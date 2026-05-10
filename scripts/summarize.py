#!/usr/bin/env python3

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(os.environ.get("BENCH_ROOT", Path(__file__).resolve().parents[1]))
RUN = os.environ.get("BENCH_RUN", "run-20260509-1")
RESULTS_DIR = ROOT / "results" / RUN

FILES = {
    "master_sql": "master.raw.txt",
    "patch_sql": "patch.raw.txt",
    "master_ext": "master.extension.raw.txt",
    "patch_ext": "patch.extension.raw.txt",
    "master_ext_scale": "master.extension.scale.raw.txt",
    "patch_ext_scale": "patch.extension.scale.raw.txt",
}


def median(values):
    sorted_values = sorted(values)
    mid = len(sorted_values) // 2
    if len(sorted_values) % 2:
        return sorted_values[mid]
    return (sorted_values[mid - 1] + sorted_values[mid]) / 2


def parse_raw(filename):
    file_path = RESULTS_DIR / filename
    if not file_path.exists():
        return {}

    groups = {}
    current = None
    for line in file_path.read_text(encoding="utf-8").splitlines():
        bench = re.match(r"^BENCH\s+(.+)$", line)
        if bench:
            current = bench.group(1).strip()
            groups.setdefault(current, [])
            continue

        time = re.match(r"^Time:\s+([0-9.]+)\s+ms$", line)
        if time and current:
            groups[current].append(float(time.group(1)))

    return groups


PARSED = {name: parse_raw(filename) for name, filename in FILES.items()}


def row(label, master_key, patch_key, bench, loops):
    master = PARSED[master_key].get(bench) if master_key else None
    patch = PARSED[patch_key].get(bench) if patch_key else None
    master_med = median(master) if master else None
    patch_med = median(patch) if patch else None
    delta_ms = patch_med - master_med if master_med is not None and patch_med is not None else None

    return {
        "label": label,
        "bench": bench,
        "loops": loops,
        "master_times_ms": master,
        "patch_times_ms": patch,
        "master_median_ms": master_med,
        "patch_median_ms": patch_med,
        "delta_ms": delta_ms,
        "delta_ns_per_wait": (delta_ms * 1e6) / loops if delta_ms is not None and loops else None,
        "pct": (delta_ms / master_med) * 100 if delta_ms is not None and master_med else None,
    }


ROWS = [
    row("SQL simple select, WAITS disabled", "master_sql", "patch_sql", "simple_select_disabled", None),
    row(
        "SQL pg_sleep(0), WAITS disabled (not useful wait signal)",
        "master_sql",
        "patch_sql",
        "wait_loop_disabled_10k",
        10000,
    ),
    row(
        "SQL EXPLAIN ANALYZE no WAITS, pg_sleep(0)",
        "master_sql",
        "patch_sql",
        "explain_analyze_no_waits_sleep_10k",
        10000,
    ),
    row("C wait loop, WAITS disabled", "master_ext_scale", "patch_ext_scale", "c_wait_loop_disabled_50m", 50000000),
    row(
        "C wait loop, EXPLAIN ANALYZE no WAITS",
        "master_ext_scale",
        "patch_ext_scale",
        "c_wait_loop_explain_no_waits_50m",
        50000000,
    ),
    row("C wait loop, EXPLAIN ANALYZE WAITS", None, "patch_ext_scale", "c_wait_loop_explain_waits_10m", 10000000),
]

patch_no_wait_row = next(r for r in ROWS if r["bench"] == "c_wait_loop_explain_no_waits_50m")
patch_wait_row = next(r for r in ROWS if r["bench"] == "c_wait_loop_explain_waits_10m")
patch_no_wait = patch_no_wait_row["patch_median_ms"] / 5
patch_wait = patch_wait_row["patch_median_ms"]
enabled_delta_ms = patch_wait - patch_no_wait
enabled_ns_per_wait = (enabled_delta_ms * 1e6) / 10000000

build = (
    "PostgreSQL 19devel, Apple clang 17, optimized default -O2, "
    "no --enable-debug, no --enable-cassert, --without-icu, "
    "jit=off, track_io_timing=off."
    if "opt" in RUN
    else "PostgreSQL 19devel, Apple clang 17, --enable-debug "
    "--enable-cassert, --without-icu, jit=off, track_io_timing=off."
)

summary = {
    "run": RUN,
    "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "build": build,
    "caveats": [
        "Build is optimized default -O2 without --enable-cassert/--enable-debug."
        if "opt" in RUN
        else "Build is --enable-debug --enable-cassert, not production-optimized.",
        "SQL pg_sleep(0) does not produce useful wait-event signal; C extension microbench is the relevant hot-path result.",
        "Runs were sequential on one local macOS machine; results are directional.",
    ],
    "rows": ROWS,
    "enabled_waits_estimate": {
        "patch_explain_no_waits_10m_equivalent_median_ms": patch_no_wait,
        "patch_explain_waits_10m_median_ms": patch_wait,
        "delta_ms": enabled_delta_ms,
        "ns_per_wait": enabled_ns_per_wait,
    },
}

RESULTS_DIR.mkdir(parents=True, exist_ok=True)
(RESULTS_DIR / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")


def fmt(value, digits=3):
    return "" if value is None else f"{value:.{digits}f}"


md = ""
md += f"# EXPLAIN WAITS microbench {RUN}\n\n"
md += f"Date: {summary['timestamp']}\n\n"
md += f"Build: {summary['build']}\n\n"
md += f"Artifacts: raw psql output and scripts are under `{ROOT}`.\n\n"
md += "## Caveats\n\n"
for caveat in summary["caveats"]:
    md += f"- {caveat}\n"
md += "\n## Medians\n\n"
md += "| Benchmark | Master median ms | Patch median ms | Delta ms | Delta ns/wait | Delta % |\n"
md += "|---|---:|---:|---:|---:|---:|\n"
for r in ROWS:
    md += (
        f"| {r['label']} | {fmt(r['master_median_ms'])} | {fmt(r['patch_median_ms'])} | "
        f"{fmt(r['delta_ms'])} | {fmt(r['delta_ns_per_wait'])} | {fmt(r['pct'], 1)} |\n"
    )
md += "\n## Enabled WAITS estimate\n\n"
md += f"Patch `EXPLAIN ANALYZE, WAITS` for 10M synthetic wait start/end pairs: {fmt(patch_wait)} ms median.\n"
md += f"Patch `EXPLAIN ANALYZE` no-WAITS normalized to 10M pairs: {fmt(patch_no_wait)} ms median.\n"
md += f"Estimated incremental enabled accounting cost: {fmt(enabled_delta_ms)} ms total, {fmt(enabled_ns_per_wait)} ns/wait.\n\n"
md += "## Raw Times\n\n"
for r in ROWS:
    master = ", ".join(str(v) for v in (r["master_times_ms"] or []))
    patch = ", ".join(str(v) for v in (r["patch_times_ms"] or []))
    md += f"- {r['label']}: master=[{master}], patch=[{patch}]\n"

(RESULTS_DIR / "summary.md").write_text(md, encoding="utf-8")

diary_dir = ROOT / "diary"
diary_dir.mkdir(parents=True, exist_ok=True)
diary = ""
diary += f"# {RUN}: EXPLAIN WAITS microbench notes\n\n"
diary += (
    "Hardcoded/условность: benchmark uses a temporary C extension outside the "
    "PostgreSQL tree to call pgstat_report_wait_start/end in a tight loop. "
    "This is bench-only and not part of the patch.\n\n"
)
diary += (
    "Hardcoded/условность: current patch preallocates 64 distinct wait event "
    "identities per statement/node accumulator; overflow keeps total calls/time "
    "without identity.\n\n"
)
diary += f"Build: {summary['build']}\n\n"
diary += (
    "Result: disabled hot-path overhead in the C loop is visible, around "
    f"{fmt(ROWS[3]['delta_ns_per_wait'])} ns per wait start/end pair by median. "
    "Enabled EXPLAIN WAITS accounting is around "
    f"{fmt(enabled_ns_per_wait)} ns per wait for a single active Result node in this synthetic case.\n\n"
)
diary += (
    "Caveat: these are directional local numbers; before pgsql-hackers we still "
    "want repeated CPU-pinned/less noisy runs on at least one Linux box.\n\n"
)
diary += f"Raw artifacts: {RESULTS_DIR}\n"
(diary_dir / f"{RUN}.md").write_text(diary, encoding="utf-8")

print(md, end="")
