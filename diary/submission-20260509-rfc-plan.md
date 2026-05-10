# submission-20260509-rfc-plan: EXPLAIN WAITS upstream plan

Current state: branch `r314tive/pg-wait-explain-mvp` has a functional core
prototype for `EXPLAIN (ANALYZE, WAITS)`.

## What is covered

- Statement-level `Statement Wait Events` counts each completed wait once per
  active statement collector.
- Parallel worker waits are accumulated into the leader's statement-level
  summary.
- Plan-node `Wait Events` are inclusive, matching the shape of EXPLAIN ANALYZE
  node timing: a wait is attributed to every active plan node captured at wait
  start.
- Parallel worker per-node waits are accumulated, including worker relaunch /
  rescan cases.
- Wait-end accounting does not allocate memory; distinct-event storage is
  preallocated and overflowed waits retain calls/time without event identity.
- Nested collectors are stacked, and query-level cleanup restores leaked inner
  node attribution state after errors.
- `WaitEventUsage` is opaque outside `wait_event.c`; callers use allocation,
  accumulation, and read accessors.

## Honest limitations

- Hardcoded/условность: each statement or plan-node accumulator stores up to
  64 distinct wait event identities.  Additional identities are summarized in
  `Unrecorded Wait Event Calls` and `Unrecorded Wait Event Time`.
- Node-level output is inclusive.  Parent and child nodes can show the same
  wait; node wait times must not be summed into a statement total.
- Per-node attribution is based on the active executor node stack at wait
  start, not on an exclusive CPU/wait ownership model.
- Per-node error scoping follows the existing executor instrumentation model:
  we do not add `PG_TRY`/`PG_FINALLY` around every node callback.  The
  statement collector's `PG_FINALLY` is the cleanup boundary.
- Local microbenchmarks are macOS-only and directional.  They are useful for
  tracking branch changes, not sufficient as final performance evidence.
- Regression tests use `pg_sleep()` wrappers plus planner GUC scaffolding to
  make some plan shapes deterministic.

## Likely pgsql-hackers objections

- Disabled hot-path overhead: `pgstat_report_wait_start/end()` now test an
  extra boolean even when `WAITS` is not used.
- Enabled overhead: accounting cost is proportional to waits times active
  node depth.
- Semantics: inclusive per-node attribution can look duplicated to users.
- Output shape: `WAITS` option name, `Statement Wait Events` top-level label,
  and separate overflow fields may need bikeshedding.
- Fixed 64-entry preallocation: reviewers may prefer a different bound,
  GUC-free rationale, or a different overflow representation.
- Test fragility: parallel plan and bitmap runtime-key tests rely on planner
  GUCs and `pg_sleep()` wrappers.
- Patch size: statement accounting, parallel support, per-node attribution,
  output formatting, docs, and tests are all intertwined.

## Suggested patch series

1. Add backend-local wait usage accumulator and `EXPLAIN (ANALYZE, WAITS)`
   statement-level output.
2. Add structured output, docs, psql completion, and basic regression tests.
3. Add parallel worker statement-level wait aggregation.
4. Add inclusive per-node wait attribution for normal executor nodes.
5. Add manually instrumented async / MultiExec / hash paths.
6. Add parallel per-node aggregation and rescan/relaunch handling.
7. Add safety hardening: no wait-end allocation, nested collector cleanup,
   opaque accumulator API.

For a first submission, consider squashing some cleanup commits into the
feature commits, but keep the semantic layers above visible enough for review.

## Benchmark plan before CommitFest

- Repeat the C wait-loop microbench on Linux, optimized build, CPU pinned if
  practical.
- Measure:
  - master vs patch, WAITS disabled, tight wait start/end loop;
  - master vs patch, `EXPLAIN ANALYZE` without `WAITS`;
  - patch `EXPLAIN ANALYZE, WAITS` with one active node;
  - patch enabled accounting with a deeper executor-node stack;
  - an actual I/O or lock-wait workload if we can make one stable.
- Report absolute ns/wait and percent delta, but position percentages from
  near-empty loops as worst-case synthetic amplification.

## Submission positioning

Submit first as RFC/WIP, not as a normal ready-to-commit CommitFest patch.
The code is functional and has correctness hardening, but the semantics,
option naming, output shape, fixed capacity, and hot-path overhead deserve
early design review before spending effort on final polish.

Suggested cover-letter framing:

- PostgreSQL already exposes current wait event identity through
  `pg_stat_activity`; this patch gives `EXPLAIN ANALYZE` an exact per-query
  view of completed wait intervals.
- Statement-level accounting is exact for waits observed by
  `pgstat_report_wait_start/end`, including parallel workers.
- Node-level accounting is intentionally inclusive and is documented as such.
- Wait-end accounting avoids allocation and critical-section ERROR risk.
- The RFC asks specifically for feedback on semantics, output shape, fixed
  accumulator capacity, and acceptable hot-path overhead.
