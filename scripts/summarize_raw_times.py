#!/usr/bin/env python3

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def usage():
    print("Usage: summarize_raw_times.py RAW_FILE OUT_PREFIX", file=sys.stderr)


if len(sys.argv) == 2 and sys.argv[1] in {"-h", "--help"}:
    usage()
    sys.exit(0)

if len(sys.argv) != 3:
    usage()
    sys.exit(2)

raw_file = Path(sys.argv[1])
out_prefix = Path(sys.argv[2])


def median(values):
    sorted_values = sorted(values)
    mid = len(sorted_values) // 2
    if len(sorted_values) % 2:
        return sorted_values[mid]
    return (sorted_values[mid - 1] + sorted_values[mid]) / 2


def mean(values):
    return sum(values) / len(values)


def mad(values, med):
    return median([abs(value - med) for value in values])


def parse_raw(text):
    groups = {}
    current = None

    for line in text.splitlines():
        bench = re.match(r"^BENCH\s+(.+)$", line)
        if bench:
            current = bench.group(1).strip()
            groups.setdefault(current, [])
            continue

        time = re.match(r"^Time:\s+([0-9.]+)\s+ms$", line)
        if time and current:
            groups[current].append(float(time.group(1)))

    return groups


benches = []
for name, values in parse_raw(raw_file.read_text(encoding="utf-8")).items():
    med = median(values) if values else None
    benches.append(
        {
            "name": name,
            "n": len(values),
            "values_ms": values,
            "median_ms": med,
            "mad_ms": mad(values, med) if values else None,
            "min_ms": min(values) if values else None,
            "max_ms": max(values) if values else None,
            "mean_ms": mean(values) if values else None,
        }
    )

summary = {
    "raw_file": str(raw_file.resolve()),
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "benches": benches,
}

out_prefix.with_suffix(".json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")


def fmt(value, digits=3):
    return "" if value is None else f"{value:.{digits}f}"


md = ""
md += "# Raw benchmark summary\n\n"
md += f"Raw file: `{raw_file.resolve()}`\n\n"
md += f"Generated: {summary['generated_at']}\n\n"
md += "| Benchmark | n | median ms | MAD ms | min ms | max ms | mean ms |\n"
md += "|---|---:|---:|---:|---:|---:|---:|\n"
for bench in benches:
    md += (
        f"| {bench['name']} | {bench['n']} | {fmt(bench['median_ms'])} | "
        f"{fmt(bench['mad_ms'])} | {fmt(bench['min_ms'])} | "
        f"{fmt(bench['max_ms'])} | {fmt(bench['mean_ms'])} |\n"
    )
md += "\n## Raw samples\n\n"
for bench in benches:
    values = ", ".join(str(value) for value in bench["values_ms"])
    md += f"- {bench['name']}: [{values}]\n"

out_prefix.with_suffix(".md").write_text(md, encoding="utf-8")
print(md, end="")
