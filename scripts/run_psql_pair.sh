#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'USAGE'
Usage:
  run_psql_pair.sh OUT_DIR MASTER_PSQL PATCH_PSQL MASTER_SQL PATCH_SQL

The script captures raw psql output for one master/patch SQL pair.  It does
not initialize clusters or install extensions; do that explicitly so cluster
state is visible in the run diary.

Environment variables:
  MASTER_CONNINFO   connection string for the master build
  PATCH_CONNINFO    connection string for the patch build
  PGOPTIONS         optional PostgreSQL session options
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -ne 5 ]]; then
	usage
	exit $([[ $# -eq 1 ]] && [[ "${1:-}" =~ ^(-h|--help)$ ]] && echo 0 || echo 2)
fi

out_dir=$1
master_psql=$2
patch_psql=$3
master_sql=$4
patch_sql=$5

mkdir -p "$out_dir"

run_one() {
	local label=$1
	local psql_bin=$2
	local conninfo=$3
	local sql=$4
	local outfile=$5

	{
		echo "# $label"
		echo "utc_start=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
		echo "psql=$psql_bin"
		echo "sql=$sql"
		echo "conninfo=${conninfo:-<default>}"
		echo "PGOPTIONS=${PGOPTIONS:-}"
		echo
		if [[ -n "$conninfo" ]]; then
			"$psql_bin" "$conninfo" -v ON_ERROR_STOP=1 -f "$sql"
		else
			"$psql_bin" -v ON_ERROR_STOP=1 -f "$sql"
		fi
		echo
		echo "utc_end=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
	} > "$outfile" 2>&1
}

run_one "master" "$master_psql" "${MASTER_CONNINFO:-}" "$master_sql" "$out_dir/master.raw.txt"
run_one "patch" "$patch_psql" "${PATCH_CONNINFO:-}" "$patch_sql" "$out_dir/patch.raw.txt"

echo "wrote $out_dir/master.raw.txt"
echo "wrote $out_dir/patch.raw.txt"
