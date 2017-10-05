  WITH RECURSIVE index_details AS (
  SELECT
    'pgbench_accounts_pkey'::text idx
),
size_in_pages_index AS (
  SELECT
    (pg_relation_size(idx::regclass) / (2^13))::int4 size_pages
  FROM
    index_details
),
page_stats AS (
  SELECT
    index_details.*,
    stats.*
  FROM
    index_details,
    size_in_pages_index,
    lateral (SELECT i FROM generate_series(1, size_pages - 1) i) series,
    lateral (SELECT * FROM bt_page_stats(idx, i)) stats
),
meta_stats AS (
  SELECT
    *
  FROM
    index_details s,
    lateral (SELECT * FROM bt_metap(s.idx)) meta
),
pages_raw AS (
  SELECT
    *
  FROM
    page_stats
  ORDER BY
    btpo DESC
),
/* XXX: Note ordering dependency within this CTE */
pages_walk(item, prior, llive_items, blk, level) AS (
  SELECT
    1,
    0,
    case when btpo_next = 0 then live_items else live_items - 1 end,
    blkno,
    btpo
  FROM
    pages_raw
  WHERE
    btpo_prev = 0
    AND btpo = (SELECT level FROM meta_stats)
  UNION
  SELECT
    CASE WHEN level = btpo THEN w.item + 1 ELSE 1 END,
    CASE WHEN level != btpo then 0 else prior + llive_items END,
    case when btpo_next = 0 then live_items else live_items - 1 end,
    blkno,
    btpo
  FROM
    pages_raw i,
    pages_walk w
  WHERE
    i.btpo_prev = w.blk OR (btpo_prev = 0 AND btpo = w.level - 1)
),
level_det as (
SELECT
format($fff$
node%1$s_%2$s[ tooltip = "Block %6$s values (high key is positioned at offset 1): &#10;%14$s" label=<<table width="210">
                  <tr>
                    -- First item on page
                    <td bgcolor='%13$s' width="30" port="f0"><font point-size="12">%3$s</font></td>
                    -- Second item on page
                    <td bgcolor='%13$s' width="30" port="f1"><font point-size="12">%4$s</font></td>
                    -- Highkey
                    <td bgcolor='#E67E22' width="30" port="f2"><font point-size="12">%5$s</font></td>
                    -- Gray box with details
                    <td bgcolor='#ECF0F1' width="120"><b><font point-size="8">Level %1$s logical page %2$s</font></b><br/><br/>Block number: %6$s<br/>live/dead items: %7$s/%8$s<br/>avg tuple width: %9$s<br/>distinct keys (no highkey): %10$s<br/>distinct block pointers: %11$s<br/>free size: %12$s</td>
                  </tr>
              </table>
             >
        ];
$fff$,
btpo, item,
/* First item */
CASE WHEN btpo != 0 THEN '-&infin;' when btpo_next = 0 then int4_from_page_data(all_items[1])::text else int4_from_page_data(all_items[2])::text end,
/* Second item */
CASE WHEN btpo_next = 0 then int4_from_page_data(all_items[2])::text else int4_from_page_data(all_items[3])::text end,
/* High key */
coalesce(CASE WHEN btpo_next != 0 THEN int4_from_page_data(all_items[1])::text END, '+&infin;'),
/* Page details */
blkno::text, live_items, dead_items, avg_item_size, distinct_real_item_keys, distinct_block_pointers, free_size,
/* Appropriate HTML color for first and second items */
case when btpo != 0 then '#F1C40F'::text else '#2ECC71'::text end,
/*
 * Tooltip values, for each page.  Doesn't seem worth using
 * int4_from_page_data() here, as that's very slow.
 */
array_to_string(all_items, '; ')
) ||
-- Use logical block numbers to build downlinks to children
--
-- XXX: This is probably broken by page deletion, where there is no downlink in
-- parent but child still has sibling pointers.  It's probably possible to fix
-- this by skipping deleted pages.
case when btpo != 0 then
  (select string_agg(format('"node%s_%s" -> "node%s_%s":f0 ', btpo, item, btpo - 1, gg), E'\n')
   from
   generate_series(prior +1, prior + distinct_block_pointers) gg)
else
  ''
end ||
-- sibling pointer:
case when btpo_next != 0 then
  (select format(E'\n\n"node%1$s_%2$s" -> "node%1$s_%3$s"[constraint=false,color=gray,style=dashed,arrowsize=0.5]', btpo, item, item + 1))
else
  ''
end
as all_level_details,

btpo, item
FROM
  pages_walk w,
  pages_raw i,
  lateral (
    SELECT
    COUNT(DISTINCT (CASE WHEN btpo_next = 0 OR itemoffset > 1 THEN (DATA COLLATE "C") END)) AS distinct_real_item_keys,
    COUNT(DISTINCT (CASE WHEN btpo_next = 0 OR itemoffset > 1 THEN (ctid::text::point)[0]::BIGINT END)) AS distinct_block_pointers,
    /* Note: displaying all values as int4 takes rather a long time */
    array_agg(nullif(data, '')) AS all_items
    FROM bt_page_items(idx, blkno)
  ) items
  WHERE w.blk = i.blkno
  /* Uncomment to avoid showing leaf level (faster): */
  /* and level > 0*/
ORDER BY btpo DESC, item
)
select
$digraph$
digraph nbtree {
graph [fontname = "monospace"];
node [shape = none,height=.1,fontname = "monospace",fontsize=6];
edge [penwidth=0.5]
$digraph$
union all
select * from (select all_level_details from level_det order by btpo DESC, item) a
union all
select '}';
