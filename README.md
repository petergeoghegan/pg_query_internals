# pg_query_internals: Query PostgreSQL internals using SQL

Current version: 0.1

Author: Peter Geoghegan [`<pg@bowt.ie>`](mailto:pg@bowt.ie)

License: <a href="https://opensource.org/licenses/postgresql">PostgreSQL license</a>

Minimum supported version: PostgreSQL 9.5 (most things work on earlier versions, though)

Requires: <a href="https://www.postgresql.org/docs/current/static/pageinspect.html">contrib/pageinspect</a>,
<a href="https://www.postgresql.org/docs/current/static/pgbuffercache.html">contrib/pg_buffercache</a>

## Overview

`pg_query_internals` is a collection of SQL queries that are useful for
inspecting the state of a PostgreSQL database.  SQL queries for querying the
contents of the buffer cache are provided, as well as for querying the
structure of a given B-Tree index, and how the index is cached.

These queries are published for educational purposes only; they are not
designed for production use.  These queries may have some hard-coded
assumptions about the underlying data being queried, although that is generally
directly noted in comments.  While the queries may be useful as a starting
point for certain types of low-level investigations, they are generally not
usable as instrumentation to find issues in production systems.

In short, the SQL queries are written for those with a specific interest in
PostgreSQL internals, and in particular the internals of the B-Tree access
method and PostgreSQL buffer manager.

### Usage

The SQL queries within `pg_query_internals.sql` are intended to be run on an
ad-hoc basis.  The queries are deliberatly not packaged as functions within an
extension.

### Other resources

For those that wish to learn more about PostgreSQL B-Tree indexes, the
following resources are suggested:

* The blogpost "Discovering the Computer Science Behind Postgres Indexes", by
  Pat Shaughnessy:

http://patshaughnessy.net/2014/11/11/discovering-the-computer-science-behind-postgres-indexes

Good high-level overview.

* The PostgreSQL nbtree README.

The authoritative source of information on PostgreSQL B-Tree indexes.

* The paper "A symmetric concurrent B-tree algorithm", from Lanin & Shasha.

This is the paper that the PostgreSQL page deletion (and page recycling)
algorithm is based on.  Although this isn't the original Lehman & Yao B-Tree
paper that first described the optimistic technique used to avoid "crabbing" of
buffer locks (these locks are sometimes called "latches" in the literature),
it is the more useful resource in my opinion.  Note that the algorithm is
implemented in a slightly different manner in PostgreSQL, though the
differences that are directly noted in the nbtree README.

Lanin & Shasha's paper is of far more practical use to implementers, who may
consider skipping the Lehman & Yao paper entirely.  For example, it
specifically takes issue with a strange tacit assumption made by the Lehman &
Yao paper: the assumption that page reads and writes are always atomic.  This
assumption justifies the Lehman & Yao contention that their algorithm requires
*no* locks during index scans.  This claim is rather a lot stronger than the
claim that only one lock is required at a time during a descent of the B-Tree,
which is all that PostgreSQL manages, and all that Lanin & Shasha see fit to
claim for their enhanced algorithm.

The Lanin & Shasha paper actually describes a practical deletion algorithm,
rather than assuming that in general page deletion can happen during a period
in which the system is offline, as Lehman & Yao rather fancifully suggest.
Since all practical requirements are met at once, the Lanin & Shasha design is
a truly comprehensive guide to implementing a real-world, high concurrency
B-Tree structure.

* "The Internals of PostgreSQL" website:

http://www.interdb.jp/pg/index.html

This website is a good general starting point for learning about PostgreSQL
internals more generally.
