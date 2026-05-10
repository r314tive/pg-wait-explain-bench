#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage:
  profile_linux_perf.sh OUT_DIR LABEL -- COMMAND [ARGS...]

Runs COMMAND under Linux perf and writes:
  OUT_DIR/LABEL.perf.data
  OUT_DIR/LABEL.perf.script
  OUT_DIR/LABEL.perf.stat.txt
  OUT_DIR/LABEL.folded       if FlameGraph stackcollapse-perf.pl is available
  OUT_DIR/LABEL.svg          if FlameGraph flamegraph.pl is available

Environment variables:
  PERF_FREQ          sample frequency, default 999
  PERF_REPEAT        perf stat repetitions, default 5
  PERF_CALLGRAPH     call graph mode, default dwarf
  FLAMEGRAPH_DIR     directory containing stackcollapse-perf.pl and flamegraph.pl
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 4 ]]; then
	usage
	exit $([[ $# -eq 1 ]] && [[ "${1:-}" =~ ^(-h|--help)$ ]] && echo 0 || echo 2)
fi

out_dir=$1
label=$2
shift 2

if [[ "${1:-}" != "--" ]]; then
	usage
	exit 2
fi
shift

mkdir -p "$out_dir"

if ! command -v perf >/dev/null 2>&1; then
	echo "perf not found" >&2
	exit 1
fi

freq=${PERF_FREQ:-999}
repeat=${PERF_REPEAT:-5}
callgraph=${PERF_CALLGRAPH:-dwarf}

perf_data="$out_dir/$label.perf.data"
perf_script="$out_dir/$label.perf.script"
perf_stat="$out_dir/$label.perf.stat.txt"

{
	echo "# command"
	printf '%q ' "$@"
	echo
	echo "# utc_start"
	date -u '+%Y-%m-%dT%H:%M:%SZ'
	echo
} > "$out_dir/$label.profile.txt"

perf stat -d -r "$repeat" -o "$perf_stat" -- "$@"
perf record -F "$freq" -g --call-graph "$callgraph" -o "$perf_data" -- "$@"
perf script -i "$perf_data" > "$perf_script"

if [[ -n "${FLAMEGRAPH_DIR:-}" &&
	  -x "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" &&
	  -x "$FLAMEGRAPH_DIR/flamegraph.pl" ]]; then
	"$FLAMEGRAPH_DIR/stackcollapse-perf.pl" "$perf_script" > "$out_dir/$label.folded"
	"$FLAMEGRAPH_DIR/flamegraph.pl" "$out_dir/$label.folded" > "$out_dir/$label.svg"
	echo "wrote $out_dir/$label.svg"
else
	echo "FlameGraph tools not found; kept raw perf data/script only" >&2
fi

echo "wrote $perf_stat"
echo "wrote $perf_data"
echo "wrote $perf_script"
