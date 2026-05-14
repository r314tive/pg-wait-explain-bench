# 2026-05-14 v1 format-only resend

CommitFest still shows CFBot as `Not processed`, and manual requeue returns
`Failed to requeue patch: 400`.

Decision: prepare a format-only v1 using the same patch content as v0, but as
one email with `0001..0007.patch` attached.  This matches Michael Paquier's
process feedback and is more likely to be consumed by the CommitFest tooling.

Hardcoded/условность: v1 does not contain code changes.  It is only a mailing
format correction.  The body explicitly says "No code changes from v0."

Verification before sending:

- generated fresh attachments from `r314tive/pg-wait-explain-rfc-v0` with
  subject prefix `RFC PATCH v1`;
- `git am` on a fresh local `master` clone succeeds;
- `git diff --check` passes after applying;
- final diff is identical to the RFC branch diff.
