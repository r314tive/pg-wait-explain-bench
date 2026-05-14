# 2026-05-14 mailing list format note

Michael Paquier pointed out that PostgreSQL community list practice is to send
a patch series in a single email rather than as one email per patch.

Action for future revisions: send one cover email to `pgsql-hackers` and attach
the `0001..000N.patch` files.  Do not use kernel-style `git send-email` output
where every patch is sent as a separate message.

For the already-sent v0, do not resend the same patchset only for formatting
unless CFBot or reviewers need a fresh attachment-based copy.  Reply briefly in
the thread acknowledging the process mistake, then use the corrected format for
v1.
