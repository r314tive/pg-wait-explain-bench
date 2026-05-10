\set ON_ERROR_STOP 1
\pset pager off
\timing on

create or replace function bench_wait_loop(integer) returns integer
as '$libdir/wait_event_bench', 'bench_wait_loop'
language C volatile strict parallel safe;

select version();
show jit;
show track_io_timing;

-- Warmup.
select bench_wait_loop(100000);

\echo BENCH c_wait_loop_disabled_5m
select bench_wait_loop(5000000);
select bench_wait_loop(5000000);
select bench_wait_loop(5000000);
select bench_wait_loop(5000000);
select bench_wait_loop(5000000);

\echo BENCH c_wait_loop_explain_no_waits_5m
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

\echo BENCH c_wait_loop_explain_waits_5m
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
