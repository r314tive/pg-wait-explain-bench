# EXPLAIN WAITS microbench run-20260509-1

Date: 2026-05-08T21:54:56.525Z

Build: PostgreSQL 19devel, Apple clang 17, --enable-debug --enable-cassert, --without-icu, jit=off, track_io_timing=off.

Artifacts: raw psql output and scripts are under `/private/tmp/pg-wait-explain-bench`.

## Caveats

- Build is --enable-debug --enable-cassert, not production-optimized.
- SQL pg_sleep(0) does not produce useful wait-event signal; C extension microbench is the relevant hot-path result.
- Runs were sequential on one local macOS machine; results are directional.

## Medians

| Benchmark | Master median ms | Patch median ms | Delta ms | Delta ns/wait | Delta % |
|---|---:|---:|---:|---:|---:|
| SQL simple select, WAITS disabled | 3.955 | 3.705 | -0.250 |  | -6.3 |
| SQL pg_sleep(0), WAITS disabled (not useful wait signal) | 0.475 | 0.436 | -0.039 | -3.900 | -8.2 |
| SQL EXPLAIN ANALYZE no WAITS, pg_sleep(0) | 0.555 | 0.532 | -0.023 | -2.300 | -4.1 |
| C wait loop, WAITS disabled | 20.639 | 28.254 | 7.615 | 0.152 | 36.9 |
| C wait loop, EXPLAIN ANALYZE no WAITS | 20.589 | 28.073 | 7.484 | 0.150 | 36.3 |
| C wait loop, EXPLAIN ANALYZE WAITS |  | 329.489 |  |  |  |

## Enabled WAITS estimate

Patch `EXPLAIN ANALYZE, WAITS` for 10M synthetic wait start/end pairs: 329.489 ms median.
Patch `EXPLAIN ANALYZE` no-WAITS normalized to 10M pairs: 5.615 ms median.
Estimated incremental enabled accounting cost: 323.874 ms total, 32.387 ns/wait.

## Raw Times

- SQL simple select, WAITS disabled: master=[4.751, 4.174, 3.955, 3.692, 3.681], patch=[3.964, 3.877, 3.664, 3.705, 3.698]
- SQL pg_sleep(0), WAITS disabled (not useful wait signal): master=[0.519, 0.472, 0.463, 0.475, 0.628], patch=[0.542, 0.423, 0.436, 0.444, 0.429]
- SQL EXPLAIN ANALYZE no WAITS, pg_sleep(0): master=[0.739, 0.595, 0.464, 0.479, 0.555], patch=[0.532, 0.498, 0.534, 0.5, 0.612]
- C wait loop, WAITS disabled: master=[22.344, 20.89, 13.6, 17.97, 20.639], patch=[28.254, 28.774, 29.789, 27.424, 27.826]
- C wait loop, EXPLAIN ANALYZE no WAITS: master=[20.472, 22.083, 19.505, 22.705, 20.589], patch=[28.898, 27.514, 28.774, 28.073, 27.764]
- C wait loop, EXPLAIN ANALYZE WAITS: master=[], patch=[325.007, 317.882, 333.604, 329.489, 330.222]
