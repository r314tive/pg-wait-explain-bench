# RFC v1 Single-Email Bundle

Purpose: resend the same patch content as v0 using the PostgreSQL community
list convention: one email with the patch series attached.

Subject:

```text
[RFC PATCH v1] Add EXPLAIN ANALYZE wait event reporting
```

Recipients:

```text
To: pgsql-hackers@postgresql.org
Cc: Michael Paquier <michael@paquier.xyz>
```

Threading:

```text
In-Reply-To: <agFR7W2yJ7p5cnxb@paquier.xyz>
References: <cover.1778280923.git.tanswis42@gmail.com> <agFR7W2yJ7p5cnxb@paquier.xyz>
```

Body:

```text
body.txt
```

Attach these files, in order:

```text
0001-Add-EXPLAIN-WAITS-statement-reporting.patch
0002-Aggregate-EXPLAIN-WAITS-from-parallel-workers.patch
0003-Attribute-EXPLAIN-WAITS-to-plan-nodes.patch
0004-Refine-EXPLAIN-WAITS-attribution-semantics.patch
0005-Harden-EXPLAIN-WAITS-accumulator-handling.patch
0006-Hide-EXPLAIN-WAITS-accumulator-internals.patch
0007-Keep-EXPLAIN-option-completion-current.patch
```

Verification:

- `git am 0001..0007` succeeds on a fresh local `master` clone.
- `git diff --check` passes after applying.
- The final diff is identical to `r314tive/pg-wait-explain-rfc-v0`.

Hardcoded/условность: v1 is format-only.  Patch content is unchanged from v0.
