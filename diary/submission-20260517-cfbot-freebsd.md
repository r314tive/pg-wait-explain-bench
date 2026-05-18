# 2026-05-17 CFBot FreeBSD regression failure

CFBot reached the test phase for CF 6753.  The FreeBSD Meson run failed in
`explain` regression output, not in compilation.

Observed failures:

- the simple `EXPLAIN (ANALYZE, WAITS) SELECT pg_sleep(...)` regression output
  sometimes included additional statement-level waits such as `IO:DsmAllocate`
  and parallel-executor IPC waits;
- JSON checks that selected the first wait-event array element could therefore
  select a real but different wait event;
- the regression test for rescanned parallel-aware per-node worker waits was
  not deterministic under the parallel regression harness, because worker
  availability and the exact parallel index-scan shape are not guaranteed.

Interpretation:

- the extra wait events are valid observed statement-level waits rather than an
  accounting bug;
- exact text output that assumes only `Timeout:PgSleep` is too strict for
  statement-level wait accounting;
- worker-relaunch/rescan aggregation remains an important behavior, but a
  plain `src/test/regress` test is the wrong place to require it unless the
  test can fully control worker availability and plan shape.

Patch direction:

- keep serial EXPLAIN output deterministic by disabling debug parallel query and
  default gather workers in `explain.sql`;
- make the text-output test check the invariant lines it needs rather than the
  full statement-level wait list;
- use JSONPath checks for the presence of `PgSleep` rather than assuming it is
  the first wait event;
- disable debug parallel query in the bitmap runtime-key attribution test;
- remove the flaky plain-regression rescan worker assertion for now.

Hardcoded/condition:

- this is a regression-test stabilization change.  It does not change wait
  accounting semantics.
- dropping the rescan worker assertion reduces automated coverage for that
  specific edge case; it should come back as an isolated TAP-style test if we
  can make worker availability and plan shape deterministic enough for CFBot.

Verification:

- `make -C src/test/regress check TESTS=explain` passed locally after installing
  the configured `/private/tmp/pgwait-install` prefix needed by this autotools
  build.
- `git diff --check` passed.

Follow-up CFBot run 6d46121:

- the same failure pattern appeared again in CFBot output, with the old
  first-element JSON checks and full text output;
- this confirms that the local stabilization must be committed and sent as the
  next revision.  It is not evidence of a new accounting-code failure.
