\set ON_ERROR_STOP 1
\pset pager off
\timing on

-- Patch-only depth-scaling workload for EXPLAIN (ANALYZE, WAITS).
--
-- Hardcoded/условность: planner GUCs below intentionally prefer nested-loop
-- plan shapes so that waits inside the innermost expression can be observed
-- under different inclusive active-node stack depths.  Before trusting a run,
-- keep the raw EXPLAIN output and verify the actual plan shape.
--
-- Hardcoded/условность: deeper queries pass outer aliases as `+ alias * 0`
-- into bench_wait_loop() to keep the inner expression dependent on outer rows
-- without changing the loop count.

set jit = off;
set max_parallel_workers_per_gather = 0;
set enable_hashjoin = off;
set enable_mergejoin = off;
set enable_memoize = off;
set enable_material = off;

create or replace function bench_wait_loop(integer) returns integer
as '$libdir/wait_event_bench', 'bench_wait_loop'
language C volatile strict parallel safe;

select bench_wait_loop(1000000);

\echo BENCH depth1_explain_no_waits_5m
explain (analyze, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);

\echo BENCH depth1_explain_waits_5m
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select bench_wait_loop(5000000);

\echo BENCH depth2_explain_no_waits_5m
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;

\echo BENCH depth2_explain_waits_5m
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0) as v) s;

\echo BENCH depth3_explain_no_waits_5m
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;

\echo BENCH depth3_explain_waits_5m
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
explain (analyze, waits, costs off, summary off, timing off, buffers off)
select sum(v)
from generate_series(1, 1) as g1(i)
cross join lateral generate_series(1, 1) as g2(j)
cross join lateral (select bench_wait_loop(5000000 + g1.i * 0 + g2.j * 0) as v) s;
