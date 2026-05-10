#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage:
  capture_env.sh OUT_DIR

Environment variables:
  POSTGRES_SRC         optional PostgreSQL source tree
  PG_CONFIG_MASTER     optional master pg_config path
  PG_CONFIG_PATCH      optional patch pg_config path
  PSQL_MASTER          optional master psql path
  PSQL_PATCH           optional patch psql path
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -ne 1 ]]; then
	usage
	exit $([[ $# -eq 1 ]] && [[ "${1:-}" =~ ^(-h|--help)$ ]] && echo 0 || echo 2)
fi

out_dir=$1
mkdir -p "$out_dir"

{
	echo "# capture_env"
	echo
	echo "utc_date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
	echo "hostname=$(hostname 2>/dev/null || true)"
	echo "user=$(id -un 2>/dev/null || true)"
	echo "shell=${SHELL:-}"
	echo

	echo "## uname"
	uname -a
	echo

	if command -v sw_vers >/dev/null 2>&1; then
		echo "## macOS"
		sw_vers
		echo
	fi

	if command -v lscpu >/dev/null 2>&1; then
		echo "## lscpu"
		lscpu
		echo
	fi

	if [[ -r /proc/cpuinfo ]]; then
		echo "## /proc/cpuinfo model lines"
		grep -E '^(processor|model name|cpu MHz|microcode|siblings|cpu cores)' /proc/cpuinfo || true
		echo
	fi

	if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
		echo "## cpu governor"
		cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort | uniq -c || true
		echo
	fi

	if command -v sysctl >/dev/null 2>&1; then
		echo "## selected sysctl"
		sysctl -a 2>/dev/null | grep -E '^(machdep.cpu|hw.cpufrequency|hw.logicalcpu|hw.physicalcpu|kern.osrelease|kern.version)' || true
		echo
	fi

	echo "## tool paths"
	for tool in cc clang gcc make git perf bpftrace psql pg_config; do
		if command -v "$tool" >/dev/null 2>&1; then
			printf '%s=%s\n' "$tool" "$(command -v "$tool")"
		else
			printf '%s=<not found>\n' "$tool"
		fi
	done
	echo

	echo "## compiler versions"
	for tool in cc clang gcc; do
		if command -v "$tool" >/dev/null 2>&1; then
			echo "### $tool"
			"$tool" --version 2>&1 | head -n 3 || true
			echo
		fi
	done

	if [[ -n "${POSTGRES_SRC:-}" && -d "$POSTGRES_SRC/.git" ]]; then
		echo "## PostgreSQL source"
		echo "POSTGRES_SRC=$POSTGRES_SRC"
		git -C "$POSTGRES_SRC" status --short --branch || true
		git -C "$POSTGRES_SRC" rev-parse HEAD || true
		git -C "$POSTGRES_SRC" log --oneline -1 || true
		echo
	fi

	for name in MASTER PATCH; do
		var="PG_CONFIG_${name}"
		pg_config_path=${!var:-}
		if [[ -n "$pg_config_path" ]]; then
			echo "## ${var}"
			echo "$pg_config_path"
			"$pg_config_path" --version
			"$pg_config_path" --configure
			"$pg_config_path" --cc
			"$pg_config_path" --cflags
			"$pg_config_path" --ldflags
			echo
		fi
	done

	for name in MASTER PATCH; do
		var="PSQL_${name}"
		psql_path=${!var:-}
		if [[ -n "$psql_path" ]]; then
			echo "## ${var}"
			echo "$psql_path"
			"$psql_path" --version
			echo
		fi
	done
} > "$out_dir/env.txt"

echo "wrote $out_dir/env.txt"
