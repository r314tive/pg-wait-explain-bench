\set ON_ERROR_STOP 1
\pset pager off
\timing on

select version();
show server_version;
show jit;
show track_io_timing;

drop table if exists bench_t;
create table bench_t as
select g as id, g % 100 as grp, repeat('x', 32) as payload
from generate_series(1, 100000) g;
create index bench_t_id_idx on bench_t(id);
analyze bench_t;

-- Warmup for catalog/cache noise.
select count(*) from bench_t where id between 1 and 100000;
select count(pg_sleep(0)) from generate_series(1, 1000);

\echo BENCH simple_select_disabled
select count(*) from bench_t where id between 1 and 100000;
select count(*) from bench_t where id between 1 and 100000;
select count(*) from bench_t where id between 1 and 100000;
select count(*) from bench_t where id between 1 and 100000;
select count(*) from bench_t where id between 1 and 100000;

\echo BENCH wait_loop_disabled_10k
select count(pg_sleep(0)) from generate_series(1, 10000);
select count(pg_sleep(0)) from generate_series(1, 10000);
select count(pg_sleep(0)) from generate_series(1, 10000);
select count(pg_sleep(0)) from generate_series(1, 10000);
select count(pg_sleep(0)) from generate_series(1, 10000);

\echo BENCH explain_analyze_no_waits_sleep_10k
explain (analyze, costs off, summary off, timing off, buffers off)
select count(pg_sleep(0)) from generate_series(1, 10000);
explain (analyze, costs off, summary off, timing off, buffers off)
select count(pg_sleep(0)) from generate_series(1, 10000);
explain (analyze, costs off, summary off, timing off, buffers off)
select count(pg_sleep(0)) from generate_series(1, 10000);
explain (analyze, costs off, summary off, timing off, buffers off)
select count(pg_sleep(0)) from generate_series(1, 10000);
explain (analyze, costs off, summary off, timing off, buffers off)
select count(pg_sleep(0)) from generate_series(1, 10000);
