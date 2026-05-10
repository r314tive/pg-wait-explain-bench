# design-20260509-api-surface: EXPLAIN WAITS public surface

Decision: keep `WaitEventUsage` and `WaitEventUsageEntry` visible in
`utils/wait_event.h` for the current patch shape, but keep collector nesting
depth private to `wait_event.c`.

Rationale: making `WaitEventUsage` fully opaque would require a larger API
change because executor nodes currently allocate per-node accumulators by
size, and EXPLAIN reads entries directly to sort and print them.  That may
still be worth doing later, but it is not a prerequisite for reducing the most
unnecessary exported state.

Change made: replace exported `pgstat_wait_event_usage_depth` with exported
`pgstat_wait_event_usage_active`.  The inline wait-reporting hot path only
needs an active/not-active branch.  Nesting depth remains backend-private
collector state.

Follow-up change: replace the public raw initializer with
`pgstat_create_wait_event_usage()`.  The raw initializer is now a private
`wait_event.c` helper, so executor setup no longer allocates `WaitEventUsage`
manually or switches memory context just to initialize it.  The structure is
still visible because EXPLAIN output currently reads entries directly.

Hardcoded/условность: this is an API-surface cleanup, not a measured
performance optimization.  It still affects the hot path, so a matching
optimized microbench run was saved as `run-20260509-opt-activeflag`.
