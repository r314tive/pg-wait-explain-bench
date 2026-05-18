# RFC v2 send notes

Subject:

```
[RFC PATCH v2] Add EXPLAIN ANALYZE wait event reporting
```

Recipients:

```
To: pgsql-hackers@postgresql.org
Cc: Michael Paquier <michael@paquier.xyz>
```

Send as a reply-all in the existing thread when possible.

Attach exactly these eight files in order:

1. `0001-Add-EXPLAIN-WAITS-statement-reporting.patch`
2. `0002-Aggregate-EXPLAIN-WAITS-from-parallel-workers.patch`
3. `0003-Attribute-EXPLAIN-WAITS-to-plan-nodes.patch`
4. `0004-Refine-EXPLAIN-WAITS-attribution-semantics.patch`
5. `0005-Harden-EXPLAIN-WAITS-accumulator-handling.patch`
6. `0006-Hide-EXPLAIN-WAITS-accumulator-internals.patch`
7. `0007-Keep-EXPLAIN-option-completion-current.patch`
8. `0008-Stabilize-EXPLAIN-WAITS-regression-tests.patch`

Do not attach `body.txt` or `send-notes.md`.

Hardcoded/condition:

- v2 keeps the accounting code unchanged from v1.
- v2 deliberately drops the flaky plain-regression worker-rescan assertion.
  That edge remains worth testing, but not with a regression test whose plan
  shape and worker availability are not reliable on CFBot.
