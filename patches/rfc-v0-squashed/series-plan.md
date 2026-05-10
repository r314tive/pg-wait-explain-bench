# EXPLAIN WAITS RFC v0 Squashed Series

This directory contains a 7-patch RFC draft generated from:

- Source branch: `r314tive/pg-wait-explain-rfc-v0`
- Base: `master`
- Relationship to MVP branch: final diff is identical to
  `r314tive/pg-wait-explain-mvp`.
- Apply check: `git am 0001..0007` succeeds on a fresh local `master` clone;
  `git diff --check origin/master...HEAD` also passes after applying.

## Patch Layout

1. `Add EXPLAIN WAITS statement reporting`
   - Adds `EXPLAIN (ANALYZE, WAITS)`.
   - Adds statement-level wait usage collection.
   - Adds initial output, docs, and basic tests.

2. `Aggregate EXPLAIN WAITS from parallel workers`
   - Adds DSM/DSA transfer for worker statement-level waits.
   - Accumulates worker waits into the leader's statement summary.

3. `Attribute EXPLAIN WAITS to plan nodes`
   - Adds plan-node wait usage.
   - Covers normal executor nodes and manually instrumented paths.
   - Adds test scaffolding notes for bitmap runtime-key attribution.

4. `Refine EXPLAIN WAITS attribution semantics`
   - Makes node attribution inclusive.
   - Captures the active node stack at wait start.
   - Adds binary lookup, overflow output separation, nested-error cleanup,
     docs, and parallel rescan test coverage.

5. `Harden EXPLAIN WAITS accumulator handling`
   - Removes wait-end allocation.
   - Adds fixed preallocation plus overflow bucket.
   - Marks inactive hot-path accounting branch as unlikely.
   - Keeps collector depth private and hides raw initialization.

6. `Hide EXPLAIN WAITS accumulator internals`
   - Makes `WaitEventUsage` opaque outside `wait_event.c`.
   - Adds accessors for EXPLAIN output and parallel aggregation.
   - Documents the accounting API boundary.

7. `Keep EXPLAIN option completion current`
   - Updates psql EXPLAIN option completion for the new option and adjacent
     existing `IO` option.

## Known RFC Discussion Points

- `WAITS` vs `WAIT_EVENTS` option name.
- `Statement Wait Events` top-level label.
- Inclusive per-node semantics and user-facing risk of duplicated-looking
  parent/child waits.
- Fixed 64 distinct wait-event identities per accumulator.
- Disabled hot-path overhead in `pgstat_report_wait_start/end()`.
- Regression test scaffolding around planner GUCs and `pg_sleep()` wrappers.
