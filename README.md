# pg-wait-explain-bench

Microbenchmarks and RFC artifacts for the PostgreSQL `EXPLAIN (ANALYZE, WAITS)` patch.

This project intentionally lives outside the PostgreSQL tree.  It contains:

- `extension/`: a bench-only C function that calls `pgstat_report_wait_start/end()` in a tight loop.
- `scripts/`: SQL workloads and result summarizer.
- `results/`: raw captured output and generated summaries.
- `diary/`: notes about assumptions, hardcoded choices, and interpretation.
- `patches/`: generated patchset exports and cover-letter drafts.
- `docs/reliable-testing-plan.md`: evidence plan for submission-quality
  benchmarking and profiling.

## Current Runs

- `run-20260509-1`: debug/cassert build.
- `run-20260509-opt`: optimized default `-O2`, no `--enable-debug`, no `--enable-cassert`.
- `run-20260509-opt-unlikely`: same optimized shape after marking inactive EXPLAIN WAITS accounting branches as `unlikely()`.
- `run-20260509-opt-activeflag`: same optimized shape after keeping collector depth private behind a boolean active flag.

Current RFC artifacts:

```sh
ls patches/rfc-v0-squashed
cat patches/rfc-v0-squashed/series-plan.md
```

Reliable testing plan:

```sh
cat docs/reliable-testing-plan.md
```

The most relevant current summary is:

```sh
cat results/run-20260509-opt-activeflag/summary.md
```

## Reproduce Shape

The existing runs were produced by building two PostgreSQL installs, one from
`master` and one from the wait-events patch branch, then installing the bench
extension into each build:

```sh
make clean all install PG_CONFIG=/path/to/master/bin/pg_config
make clean all install PG_CONFIG=/path/to/patch/bin/pg_config
```

The extension exposes:

```sql
create or replace function bench_wait_loop(integer) returns integer
as '$libdir/wait_event_bench', 'bench_wait_loop'
language C volatile strict parallel safe;
```

The scaled workloads are:

```sh
psql -f scripts/bench_extension_scale_master.sql
psql -f scripts/bench_extension_scale_patch.sql
```

Generate summaries with:

```sh
BENCH_RUN=run-20260509-opt scripts/summarize.py
```

`BENCH_ROOT` can be set if running the summarizer from another location.
For ad hoc raw files that contain `BENCH ...` markers and psql `Time:` lines:

```sh
scripts/summarize_raw_times.py results/run-YYYYMMDD-linux/depth.raw.txt \
  results/run-YYYYMMDD-linux/depth-summary
```

For a Linux evidence run, start each run directory by capturing metadata:

```sh
POSTGRES_SRC=/path/to/postgresql \
PG_CONFIG_MASTER=/path/to/master/bin/pg_config \
PG_CONFIG_PATCH=/path/to/patch/bin/pg_config \
scripts/capture_env.sh results/run-YYYYMMDD-linux
```

CPU profiling helpers:

```sh
scripts/profile_linux_perf.sh results/run-YYYYMMDD-linux enabled-waits -- \
  /path/to/patch/bin/psql -v ON_ERROR_STOP=1 -f scripts/bench_extension_scale_patch.sql

scripts/profile_linux_wait_uprobes.sh results/run-YYYYMMDD-linux /path/to/postgres PID 30
scripts/profile_linux_offcpu.sh results/run-YYYYMMDD-linux PID 30
```

## Notes

These benchmarks are intentionally synthetic.  They isolate the wait-reporting
hot path and are useful for comparing branch overhead, not for predicting
end-to-end query latency.
