# EXPLAIN WAITS microbench run-20260509-opt-activeflag

Date: 2026-05-08T22:11:34.466Z

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
| C wait loop, WAITS disabled | 17.187 | 25.232 | 8.045 | 0.161 | 46.8 |
| C wait loop, EXPLAIN ANALYZE no WAITS | 18.138 | 23.682 | 5.544 | 0.111 | 30.6 |
| C wait loop, EXPLAIN ANALYZE WAITS |  | 305.380 |  |  |  |

## Enabled WAITS estimate

Patch `EXPLAIN ANALYZE, WAITS` for 10M synthetic wait start/end pairs: 305.380 ms median.
Patch `EXPLAIN ANALYZE` no-WAITS normalized to 10M pairs: 4.736 ms median.
Estimated incremental enabled accounting cost: 300.644 ms total, 30.064 ns/wait.

## Raw Times

- SQL simple select, WAITS disabled: master=[], patch=[]
- SQL pg_sleep(0), WAITS disabled (not useful wait signal): master=[], patch=[]
- SQL EXPLAIN ANALYZE no WAITS, pg_sleep(0): master=[], patch=[]
- C wait loop, WAITS disabled: master=[17.187, 21.122, 21.189, 15.113, 16.412], patch=[32.514, 26.664, 25.232, 24.739, 24.575]
- C wait loop, EXPLAIN ANALYZE no WAITS: master=[18.659, 15.312, 18.115, 18.138, 21.589], patch=[24.029, 23.604, 23.642, 23.682, 23.691]
- C wait loop, EXPLAIN ANALYZE WAITS: master=[], patch=[310.321, 320.639, 303.926, 305.38, 304.067]
