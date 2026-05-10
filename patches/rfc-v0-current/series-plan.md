# EXPLAIN WAITS RFC v0 Patch Series Plan

This directory contains a raw `git format-patch` export of the current branch:

- Source branch: `r314tive/pg-wait-explain-mvp`
- Base: `master`
- Raw patches: `0000-cover-letter.patch` through `0022-*.patch`
- Intent: preserve the exact current development history as an artifact
- Apply check: `git am 0001..0022` succeeds on a fresh local `master` clone;
  `git diff --check master...HEAD` also passes after applying.

The raw 22-patch series is useful for review of how the branch evolved, but it
is too fine-grained and cleanup-heavy for a first pgsql-hackers RFC.  The first
public RFC should probably be a smaller logical series.

## Proposed 7-Patch RFC Layout

### 0001 statement-level wait accounting

Goal: introduce backend-local exact wait usage collection and expose
`EXPLAIN (ANALYZE, WAITS)` statement-level output.

Fold from current history:

- `cbe631eb822 Add EXPLAIN WAITS wait event timing`
- relevant parts of `db3cbce6b45 Use binary lookup for EXPLAIN WAITS events`
- relevant parts of `5134e5cba2b Avoid allocation while ending EXPLAIN WAITS`
- relevant parts of `861b5a6783c Mark EXPLAIN WAITS accounting as unlikely`
- relevant API cleanup from `6fdd28b5af4`, `96de0592d2c`, `57df2e730fa`,
  `e1cf8b58f06`

Notes: this patch should already contain the no-allocation wait-end design and
opaque accumulator API so reviewers do not first see a known-unsafe version.

### 0002 output, docs, completion, basic tests

Goal: add structured output shape, SGML docs, psql tab completion, and basic
statement/node JSON/text tests.

Fold from current history:

- `2b2b8054d53 Structure EXPLAIN WAITS output`
- `6feb3f402c4 Document EXPLAIN WAITS semantics`
- `51f5f623b3c Separate unrecorded EXPLAIN WAITS output`
- `f857f5a6cd1 Clarify EXPLAIN WAITS output semantics`
- `0447dcc64ef Keep EXPLAIN option completion current`
- basic test parts from `cbe631eb822`

Notes: keep the output-shape discussion explicit in the cover letter because
`WAITS`, `Statement Wait Events`, and overflow fields are review targets.

### 0003 parallel statement-level aggregation

Goal: aggregate parallel worker statement-level waits into leader output.

Fold from current history:

- `1213f021c76 Aggregate EXPLAIN WAITS from parallel workers`

Notes: keep this separate from per-node worker aggregation; statement-level
correctness is easier to review independently.

### 0004 inclusive per-node attribution

Goal: add inclusive plan-node wait usage for normal executor node execution.

Fold from current history:

- `4f9984a8016 Attribute EXPLAIN WAITS to plan nodes`
- `68fdbf1f178 Make EXPLAIN WAITS node attribution inclusive`
- `40d44bdbb32 Use wait-start stack for EXPLAIN WAITS attribution`
- `47d3ee3646a Restore EXPLAIN WAITS node stack after nested errors`
- nested/error tests from `47d3ee3646a`

Notes: this is the core semantic patch.  Be explicit that attribution captures
the active node stack at wait start and is inclusive by design.

### 0005 manual executor paths

Goal: cover paths that manually perform instrumentation rather than going
through the normal `ExecProcNode` wrapper.

Fold from current history:

- `ad216fd972b Attribute EXPLAIN WAITS in manual executor paths`
- bitmap runtime-key test from `5aaedc2bc5e`

Notes: call out that the Bitmap Index Scan test uses planner GUCs and a STABLE
PL/pgSQL `pg_sleep()` wrapper as regression-test scaffolding.

### 0006 parallel per-node aggregation

Goal: propagate and merge worker per-node wait usage, including worker
relaunch/rescan cases.

Fold from current history:

- per-node portions of `1213f021c76`
- `b8a6a97b74f Test EXPLAIN WAITS parallel rescan accounting`

Notes: keep the rescan/relaunch merge behavior visible; replacing DSA entries
instead of accumulating was a real correctness risk.

### 0007 hardening and API boundary

Goal: consolidate safety and reviewer-facing cleanup.

Fold from current history:

- `11e27d92107 Harden EXPLAIN WAITS accounting`
- `5134e5cba2b Avoid allocation while ending EXPLAIN WAITS`
- `861b5a6783c Mark EXPLAIN WAITS accounting as unlikely`
- `6fdd28b5af4 Keep EXPLAIN WAITS collector depth private`
- `96de0592d2c Hide EXPLAIN WAITS accumulator initialization`
- `57df2e730fa Make EXPLAIN WAITS usage accumulator opaque`
- `e1cf8b58f06 Document EXPLAIN WAITS accounting API boundary`

Notes: in an ideal final series, most of this should be folded into earlier
patches rather than left as a separate "fix what we knowingly broke" patch.
For RFC review, keeping some of it visible can help reviewers see the safety
decisions.

## Before Sending

- Produce a squashed/reordered branch from this plan, or send the raw series
  only if the cover letter clearly says it is intentionally work-log style.
- Re-run:
  - `make -s -j4`
  - `make -C doc/src/sgml check`
  - `make -s -C src/bin/psql`
  - `make -C src/test/regress check-tests TESTS='test_setup create_index explain'`
  - `git diff --check`
- Add Linux optimized benchmark results before a non-RFC CommitFest entry.
- Decide whether `WAITS` should be renamed to `WAIT_EVENTS` before public
  bikeshedding starts.
