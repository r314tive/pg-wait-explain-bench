# EXPLAIN WAITS microbench run-20260509-opt

Date: 2026-05-08T21:54:56.554Z

Build: PostgreSQL 19devel, Apple clang 17, optimized default -O2, no --enable-debug, no --enable-cassert, --without-icu, jit=off, track_io_timing=off.

Artifacts: raw psql output and scripts are under `/private/tmp/pg-wait-explain-bench`.

## Caveats

- Build is optimized default -O2 without --enable-cassert/--enable-debug.
- SQL pg_sleep(0) does not produce useful wait-event signal; C extension microbench is the relevant hot-path result.
- Runs were sequential on one local macOS machine; results are directional.

## Medians

| Benchmark | Master median ms | Patch median ms | Delta ms | Delta ns/wait | Delta % |
|---|---:|---:|---:|---:|---:|
| SQL simple select, WAITS disabled |  |  |  |  |  |
| SQL pg_sleep(0), WAITS disabled (not useful wait signal) |  |  |  |  |  |
| SQL EXPLAIN ANALYZE no WAITS, pg_sleep(0) |  |  |  |  |  |
| C wait loop, WAITS disabled | 21.931 | 30.848 | 8.917 | 0.178 | 40.7 |
| C wait loop, EXPLAIN ANALYZE no WAITS | 21.098 | 29.865 | 8.767 | 0.175 | 41.6 |
| C wait loop, EXPLAIN ANALYZE WAITS |  | 321.165 |  |  |  |

## Enabled WAITS estimate

Patch `EXPLAIN ANALYZE, WAITS` for 10M synthetic wait start/end pairs: 321.165 ms median.
Patch `EXPLAIN ANALYZE` no-WAITS normalized to 10M pairs: 5.973 ms median.
Estimated incremental enabled accounting cost: 315.192 ms total, 31.519 ns/wait.

## Raw Times

- SQL simple select, WAITS disabled: master=[], patch=[]
- SQL pg_sleep(0), WAITS disabled (not useful wait signal): master=[], patch=[]
- SQL EXPLAIN ANALYZE no WAITS, pg_sleep(0): master=[], patch=[]
- C wait loop, WAITS disabled: master=[36.951, 26.527, 21.931, 21.574, 19.844], patch=[43.633, 32.915, 30.848, 26.255, 28.643]
- C wait loop, EXPLAIN ANALYZE no WAITS: master=[21.851, 21.098, 21.611, 19.277, 21.047], patch=[29.865, 28.811, 28.659, 35.378, 31.745]
- C wait loop, EXPLAIN ANALYZE WAITS: master=[], patch=[324.272, 319.436, 316.999, 321.165, 331.806]
