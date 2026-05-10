# design-20260509-opaque-usage: EXPLAIN WAITS accumulator opacity

Decision: make `WaitEventUsage` opaque outside `wait_event.c`.

Rationale: executor and EXPLAIN callers should not depend on accumulator
layout, nesting links, overflow fields, or the preallocated entry array.
The visible type is now only an incomplete `WaitEventUsage`; callers allocate
or start collectors through wait-event APIs and read reportable data through
accessors.

Public data that remains: `WaitEventUsageEntry` is still visible because it is
the serialization unit for EXPLAIN output and parallel-worker DSM/DSA transfer.
It contains only the stable report tuple: wait event identity, calls, and time.

Hardcoded/условность: this does not change the 64 distinct-event preallocation
limit.  It only hides the accumulator layout so the limit and overflow storage
remain implementation details.

Error-scope note: per-node wait attribution still follows the existing
executor instrumentation model.  We do not add `PG_TRY`/`PG_FINALLY` around
every node callback, because `InstrStopNode()` itself is not protected this
way and doing so would add broad hot-path overhead.  Query-level EXPLAIN WAITS
collection is protected by `PG_FINALLY`; ending that collector restores the
node wait-attribution stack to the saved outer state after errors.
