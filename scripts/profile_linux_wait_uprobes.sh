#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage:
  profile_linux_wait_uprobes.sh OUT_DIR POSTGRES_BIN PID DURATION_SECONDS

Uses bpftrace uprobes on pgstat_report_wait_start/end() to sanity-check wait
start/end frequency and duration histograms for one running postgres process.

This is diagnostic only.  Probe overhead means it must not be used as the
ground truth for nanosecond-level overhead claims.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -ne 4 ]]; then
	usage
	exit $([[ $# -eq 1 ]] && [[ "${1:-}" =~ ^(-h|--help)$ ]] && echo 0 || echo 2)
fi

out_dir=$1
postgres_bin=$2
pid=$3
duration=$4

mkdir -p "$out_dir"

if ! command -v bpftrace >/dev/null 2>&1; then
	echo "bpftrace not found" >&2
	exit 1
fi

script="$out_dir/wait_uprobes.bt"
out="$out_dir/wait_uprobes.txt"

cat > "$script" <<BT
uprobe:$postgres_bin:pgstat_report_wait_start
/pid == $pid/
{
	@starts[tid] = nsecs;
	@start_count[arg0] = count();
}

uprobe:$postgres_bin:pgstat_report_wait_end
/pid == $pid && @starts[tid]/
{
	@dur_us = hist((nsecs - @starts[tid]) / 1000);
	@end_count = count();
	delete(@starts[tid]);
}

interval:s:$duration
{
	exit();
}
BT

sudo bpftrace "$script" > "$out"
echo "wrote $script"
echo "wrote $out"
