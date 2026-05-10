# 2026-05-11 reliable comparison track

Goal: move from local directional microbenchmarks to evidence that is useful
for pgsql-hackers review.

Hardcoded/условность: the existing `bench_wait_loop()` extension is bench-only.
It calls `pgstat_report_wait_start/end()` directly with `WAIT_EVENT_PG_SLEEP`.
This isolates hot-path overhead but does not model real blocking behavior.

Hardcoded/условность: eBPF/perf tooling is Linux-specific in this plan.  The
current local macOS numbers remain smoke checks only unless repeated on a
controlled Linux machine.

Non-obvious point: eBPF is not the source of truth for PostgreSQL wait-event
semantics.  It can validate that a backend is spending time off-CPU or that
`pgstat_report_wait_start/end()` is being called, but it cannot reconstruct
EXPLAIN's statement/node attribution rules from kernel stacks alone.

Non-obvious point: CPU flamegraphs are most useful for enabled accounting,
especially the fixed-array lookup/aggregation path.  They are not precise
enough to prove sub-nanosecond disabled overhead by themselves.

Local environment note: Docker is available and reports a Linux/aarch64 daemon,
but this is Docker Desktop on macOS.  Use it only for script portability or
functional smoke checks, not for submission-quality timing, perf, or eBPF
claims.

Next required evidence:

1. Same-base `master` vs patch builds on Linux.
2. Captured environment metadata with CPU/governor/compiler/configure details.
3. Repeated paired synthetic hot-path runs.
4. Patch-only enabled depth-scaling run.
5. `perf record` CPU flamegraph for enabled WAITS accounting.
6. Off-CPU or uprobe diagnostic run for a real wait case such as lock wait or
   `pg_sleep()`.

Hardcoded/условность: `scripts/bench_depth_patch.sql` currently uses planner
GUCs (`enable_hashjoin=off`, `enable_mergejoin=off`, `enable_memoize=off`,
`enable_material=off`, `max_parallel_workers_per_gather=0`) to shape nested
plans.  This is acceptable for a benchmark candidate, but every saved run must
also save the raw EXPLAIN output and explicitly confirm the actual plan shape.

Hardcoded/условность: depth-scaling queries pass outer aliases into
`bench_wait_loop()` as `+ alias * 0`.  This keeps the loop count unchanged but
makes the inner expression formally dependent on outer rows, reducing the
chance that the planner chooses an unrelated shape.
