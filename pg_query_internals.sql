------------------
-- Dependencies --
------------------
create extension pageinspect;
create extension pg_buffercache;

--------------------------
-- B-Tree balance stats --
--------------------------
--
-- Among B-Tree indexes, what proportion are leaf pages, internal pages and
-- root pages?  Note that a single non-meta page B-Tree, which has only a root
-- page yet to undergo a root page split counts as only having a single leaf
-- page.
with tots as (
  SELECT
    count(*) c,
    avg(live_items) avg_live_items,
    avg(dead_items) avg_dead_items,
    avg(avg_item_size) avg_item_size,
    u.type,
    r.oid
  from
    (select
      c.oid,
      -- Don't count meta-page, or trust pg_class.relpages:
      generate_series(1, (select (pg_relation_size(c.oid) / (2^13))::int4) - 1) i
    from
      pg_index i
      join pg_opclass op on i.indclass[0] = op.oid
      join pg_am am on op.opcmethod = am.oid
      join pg_class c on i.indexrelid = c.oid
    where am.amname = 'btree') r,
    lateral (select * from bt_page_stats(r.oid::regclass::text, i)) u
group by r.oid, type)
select
  ct.relname table_name,
  tots.oid::regclass::text index_name,
  upper(type) page_type,
  c npages,
  to_char(avg_live_items, '990.999') as avg_live_items,
  to_char(avg_dead_items, '990.999') as avg_dead_items,
  to_char(avg_item_size, '990.999') as avg_item_size,
  to_char(c/sum(c) over(partition by tots.oid) * 100, '990.999') || ' %' as prop_of_index
from tots
  join pg_index i on i.indexrelid = tots.oid
  join pg_class ct on ct.oid = i.indrelid
order by ct.relnamespace, table_name, index_name, npages, type;

----------------------------
-- B-Tree root page stats --
----------------------------
with index_details as (
  select
    'some_index'::text idx
),
meta_stats as (
  select
  *
  from index_details s,
  lateral (select * from bt_metap(s.idx)) meta),
root_stats as (
  select
    idx,
    root,
    level,
    fastroot,
    fastlevel,
    stats.*
  from
    meta_stats s,
    lateral (select * from bt_page_stats(idx, root)) stats)
select
  root_stats.*
from
  root_stats;

------------------------------------------------------------
-- Summarize internal (non-leaf) B-Tree levels, key space --
------------------------------------------------------------
--
-- Shows internal pages (including root page) in logical order, along with high
-- key data that determines logically ordering. (This is an upper bound on page
-- data).
--
-- Should work with most types of data.  Things like varlena headers will look
-- a bit funny, but this should be easy enough to wade through or tweak.
with recursive index_details as (
  select
    'some_text_index'::text idx
),
size_in_pages_index as (
  select
    (pg_relation_size(idx::regclass) / (2^13))::int4 size_pages
  from
    index_details
),
page_stats as (
  select
    index_details.*,
    stats.*
  from
    index_details,
    size_in_pages_index,
    lateral (select i from generate_series(1, size_pages - 1) i) series,
    lateral (select * from bt_page_stats(idx, i)) stats),
internal_page_stats as (
  select
    *
  from
    page_stats
  where
    type != 'l'),
meta_stats as (
  select
    *
  from
    index_details s,
    lateral (select * from bt_metap(s.idx)) meta),
internal_items as (
  select
    *
  from
    internal_page_stats
  order by
    btpo desc),
-- XXX: Note ordering dependency within this CTE, on internal_items
ordered_internal_items(item, blk, level) as (
  select
    1,
    blkno,
    btpo
  from
    internal_items
  where
    btpo_prev = 0
    and btpo = (select level from meta_stats)
  union
  select
    case when level = btpo then o.item + 1 else 1 end,
    blkno,
    btpo
  from
    internal_items i,
    ordered_internal_items o
  where
    i.btpo_prev = o.blk or (btpo_prev = 0 and btpo = o.level - 1)
)
select
  idx,
  btpo as level,
  item as l_item,
  blkno,
  btpo_prev,
  btpo_next,
  btpo_flags,
  type,
  live_items,
  dead_items,
  avg_item_size,
  page_size,
  free_size,
  -- Only non-rightmost pages have high key.
  --
  -- XXX: To get this to work with a non-text index, fiddle with the expression
  -- that extracts from the "data" bt_page_items column.
  --
  -- Data is formed starting after varlena header bytes. NUL bytes often appear
  -- due to alignment considerations, but aren't valid utf-8.  We switch NUL
  -- bytes with raw bytes that make what looks like a text output function
  -- escaped NUL byte (non-NUL special bytes will look like this without our
  -- help, but we need to take special measures for NUL)
  case when btpo_next != 0 then (select convert_from(decode(regexp_replace(data, ' 0{2}', '5C783030', 'g'), 'hex'), 'utf-8')
                                 from bt_page_items(idx, blkno) where itemoffset = 1) end as highkey
from
  ordered_internal_items o
  join internal_items i on o.blk = i.blkno
order by btpo desc, item;

---------------------------------------------------------
-- Get a quick view of B-Tree buffercache usage counts --
---------------------------------------------------------
select
  c.relname,
  bt.type,
  count(*),
  rl.*,
  avg(case when bf.isdirty then 1.0 else 0.0 end) as avg_is_dirty,
  avg(bf.usagecount) as avg_usagecount
from
  pg_buffercache bf
  join pg_class c on c.oid = pg_filenode_relation(bf.reltablespace, bf.relfilenode)
  join pg_index i on i.indexrelid = c.oid
  join pg_opclass op on i.indclass[0] = op.oid
  join pg_am am on op.opcmethod = am.oid
  join lateral bt_page_stats(c.oid::regclass::text, bf.relblocknumber::int4) as bt on true
  join lateral pg_relation_size(c.oid) as rl on true
where am.amname = 'btree' and bf.relblocknumber > 0
group by c.relname, bt.type
order by c.relname, bt.type;

-------------------------------------------------------------------------------
-- Details caching analysis, for testing clocksweep efficiency in production --
-------------------------------------------------------------------------------

-- In first pass, create materialized copy of pg_buffercache view:
create materialized view bufcacheview as
select * from pg_buffercache;

-- Then, materialize bt page stats (this needs to happen afterwards, to not
-- spoil cache):
create materialized view btree_pages as
select
  r.oid as pg_class_oid,
  r.i as relblocknumber,
  upper(u.type) as type,
  live_items,
  dead_items,
  avg_item_size
from
  (select
     c.oid,
     -- Don't rely on potentially stale pg_class.relpages here:
     generate_series(1, (select (pg_relation_size(c.oid) / (2^13))::int4) - 1) i
   from
     pg_index i
     join pg_opclass op on i.indclass[0] = op.oid
     join pg_am am on op.opcmethod = am.oid
     join pg_class c on i.indexrelid = c.oid
   where am.amname = 'btree') r,
  lateral (select * from bt_page_stats(r.oid::regclass::text, i)) u
order by r.oid, u.type, r.i;

-- Finally, put it together.  Show how well each class of B-Tree page is
-- cached, with standard buffercache statistics for each, rolled-up:
select
  pg_class_oid::regclass as index_name,
  pg_size_pretty(pg_relation_size(pg_class_oid)) as index_relation_size,
  type,
  count(*) as blocks,
  sum(case when bc.relblocknumber is null then 0 else 1 end) as buffers,
  sum(case when bc.relblocknumber is null then 0.0 else 1.0 end) / count(*) as prop_cached,
  sum(case when bc.isdirty then 1 else 0 end) as are_dirty,
  avg(coalesce(usagecount, 0)) as avg_usagecount,
  avg(pinning_backends) as avg_pinning_backends_in_cache,
  var_pop(bc.relblocknumber) as var_pop_blocks_in_cache
from
  btree_pages btp
  join pg_class c on btp.pg_class_oid = c.oid
  left join bufcacheview bc on c.relfilenode = bc.relfilenode
                               and btp.relblocknumber = bc.relblocknumber
group by rollup(pg_class_oid, type)
order by pg_relation_size(pg_class_oid) desc nulls last, pg_class_oid,
  -- Force "Root, internal, leaf" ordering ("nulls last" avoids breaking
  -- "rollup"):
  case type when 'R' then 0 when 'I' then 2 when 'L' then 3 end nulls last;

-------------------------------------------------
-- Higher-level summary of entire buffer cache --
-------------------------------------------------
--
-- (Note: this isn't exactly comparable to above, since proportions are stuff
-- in cache only here, not all blocks.  Actually, some thigns above are for
-- buffer cache only, others are all blocks.)
select
  c.oid::regclass,
  pg_size_pretty(pg_relation_size(c.oid)) as index_relation_size,
  c.relkind,
  case relforknumber
  when 0 then
    'Main Fork'
  when 1 then
    'Freespace Map'
  when 2 then
    'Visibility Map'
  when 3 then
    'Init Fork'
  end page_type,
  count(*) as buffers,
  sum(case when bc.isdirty then 1 else 0 end) as are_dirty,
  avg(usagecount) as avg_usagecount,
  avg(pinning_backends) as avg_pinning_backends,
  var_pop(bc.relblocknumber) as var_pop_blocks_in_cache
from
  bufcacheview bc
  join pg_class c on bc.relfilenode = c.relfilenode
group by rollup(c.oid, c.relkind, relforknumber)
order by pg_relation_size(c.oid) desc nulls last, c.oid, relforknumber;
