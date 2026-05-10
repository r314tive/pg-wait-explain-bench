#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage:
  profile_linux_offcpu.sh OUT_DIR PID DURATION_SECONDS

Captures off-CPU stacks for a running backend using BCC offcputime if
available.  This is useful for real waits such as locks, sleeps, and I/O.

Supported commands, first match wins:
  offcputime-bpfcc
  offcputime

The output is diagnostic only and should be interpreted together with
PostgreSQL EXPLAIN WAITS output.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -ne 3 ]]; then
	usage
	exit $([[ $# -eq 1 ]] && [[ "${1:-}" =~ ^(-h|--help)$ ]] && echo 0 || echo 2)
fi

out_dir=$1
pid=$2
duration=$3
mkdir -p "$out_dir"

if command -v offcputime-bpfcc >/dev/null 2>&1; then
	cmd=(sudo offcputime-bpfcc -df -p "$pid" "$duration")
elif command -v offcputime >/dev/null 2>&1; then
	cmd=(sudo offcputime -df -p "$pid" "$duration")
else
	echo "offcputime-bpfcc/offcputime not found" >&2
	exit 1
fi

{
	echo "# command"
	printf '%q ' "${cmd[@]}"
	echo
	echo "# utc_start"
	date -u '+%Y-%m-%dT%H:%M:%SZ'
	echo
	"${cmd[@]}"
} > "$out_dir/offcpu.txt"

echo "wrote $out_dir/offcpu.txt"
