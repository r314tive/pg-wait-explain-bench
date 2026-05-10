# EXPLAIN WAITS reliable testing plan

This document defines the evidence we want before making stronger performance
claims about `EXPLAIN (ANALYZE, WAITS)`.

The goal is not to prove that the feature has zero overhead.  The goal is to
separate three different questions:

1. What is the disabled hot-path cost of checking whether EXPLAIN wait
   accounting is active?
2. What is the enabled accounting cost per completed wait event, as a function
   of active plan-node depth?
3. Does the reported wait-event picture agree with independent external
   observations for real blocking waits?

## Comparison Rules

- Compare a clean `master` build against the patch branch rebased on the same
  `master` commit.
- Use identical compiler, configure options, CFLAGS, LDFLAGS, extensions,
  PostgreSQL settings, filesystem, and CPU placement.
- Keep JIT off unless the benchmark is explicitly about JIT interactions.
- Keep `track_io_timing` fixed and documented.
- Alternate runs between master and patch instead of running all master runs
  first.  A simple sequence is warmup, A, B, B, A repeated several times.
- Report medians, median absolute deviation, min/max, and raw samples.  Do not
  report only percentages when the denominator is a near-empty loop.
- Save raw psql output, environment metadata, PostgreSQL config metadata,
  git SHAs, and profiling artifacts in the run directory.

## Benchmark Layers

### 1. Synthetic hot path

Use the bench-only C extension in `extension/` to call
`pgstat_report_wait_start/end()` in a tight loop.  This is the right benchmark
for disabled hot-path deltas because it isolates the branch and avoids SQL
executor noise.

Required cases:

- master: `select bench_wait_loop(N)`
- patch: `select bench_wait_loop(N)` with `WAITS` disabled
- master: `EXPLAIN (ANALYZE)` around `bench_wait_loop(N)`
- patch: `EXPLAIN (ANALYZE)` around `bench_wait_loop(N)` with `WAITS` disabled
- patch: `EXPLAIN (ANALYZE, WAITS)` around `bench_wait_loop(N)`

### 2. Depth scaling

The enabled node-level cost is expected to be proportional to:

```text
number_of_completed_waits * active_plan_depth
```

We need a patch-only depth-scaling benchmark that produces a stable number of
waits under plan shapes with different active-node stack depths.  The current
C loop exercises a shallow plan and is not enough for this question.

Candidate workload:

```sh
/path/to/patch/bin/psql -v ON_ERROR_STOP=1 \
  -f scripts/bench_depth_patch.sql \
  > results/run-YYYYMMDD-linux/depth.raw.txt 2>&1

scripts/summarize_raw_times.py \
  results/run-YYYYMMDD-linux/depth.raw.txt \
  results/run-YYYYMMDD-linux/depth-summary
```

Hardcoded/условность: `bench_depth_patch.sql` disables several planner choices
to prefer nested-loop shapes.  Treat a run as invalid until the raw EXPLAIN
output has been checked and the intended plan-depth difference is visible.
It also passes outer aliases into `bench_wait_loop()` as `+ alias * 0` to keep
the intended dependency without changing the loop count.

### 3. Real query smoke tests

Use real blocking operations to confirm that reported event identities and
statement totals make sense:

- `Timeout:PgSleep` via `pg_sleep()` for deterministic non-I/O waits.
- Lock waits using two sessions and a row/table lock conflict.
- Storage I/O waits only on a controlled machine where cache state can be
  manipulated and documented.
- Parallel query waits with worker aggregation enabled.

These tests are for semantic confidence.  They are not enough for hot-path
overhead claims.

## Profiling

### CPU flamegraphs

CPU flamegraphs are useful for enabled accounting overhead.  They should show
where time goes when `EXPLAIN (ANALYZE, WAITS)` processes many completed waits.

Use Linux `perf record` with call stacks.  If Brendan Gregg's FlameGraph tools
are available, also save folded stacks and SVG output.  Keep raw `perf.data`
and `perf script` output.

### eBPF / off-CPU

eBPF should be treated as an independent diagnostic, not as the authoritative
source for EXPLAIN semantics.

Good uses:

- off-CPU profiling of real blocking waits;
- uprobe sanity checks around `pgstat_report_wait_start/end()`;
- confirming that real sleeps/locks are externally visible as blocking time.

Bad uses:

- claiming exact PostgreSQL wait-event attribution from kernel stacks alone;
- using eBPF measurements from the same process as low-overhead ground truth;
- comparing tiny nanosecond-level hot-path deltas while probes are enabled.

## Submission-Quality Evidence

Before citing numbers on pgsql-hackers as performance evidence, we want:

- at least one Linux run on a quiet machine;
- CPU governor, turbo, SMT, NUMA, and CPU affinity documented;
- same-base master and patch builds;
- at least 20 measured samples per primary case after warmup;
- raw artifacts committed or archived;
- flamegraph or perf data for the enabled path;
- explicit wording that local macOS numbers are smoke checks only.

## Docker Desktop Caveat

Docker Desktop on macOS can be useful for checking that Linux scripts execute
and for catching obvious portability mistakes.  It should not be used for
submission-quality timing, perf, or eBPF conclusions because the workload runs
inside a VM with host scheduling and virtualization noise outside PostgreSQL's
control.
