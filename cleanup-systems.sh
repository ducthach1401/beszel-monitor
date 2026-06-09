#!/usr/bin/env bash
set -eu

usage() {
  cat <<'EOF'
Usage:
  ./cleanup-systems.sh [--days N] [--apply]

Env:
  BESZEL_VOLUME   Docker volume name for hub data. Default: beszel_data

Options:
  --days N    Delete systems not "up" and not updated for N days or more. Default: 0
  --apply     Actually delete. Without this flag, script only prints matches.

Notes:
  - This script edits the Beszel SQLite database inside the Docker volume.
  - It only deletes rows from the "systems" table shown on the dashboard.
EOF
}

days=0
apply=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --days)
      days="${2:-}"
      shift 2
      ;;
    --apply)
      apply=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -f .env.cleanup ]; then
  set -a
  . ./.env.cleanup
  set +a
fi

volume="${BESZEL_VOLUME:-beszel_data}"
cutoff="$(
  python3 - <<PY
import datetime as dt
print((dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=${days})).strftime("%Y-%m-%d %H:%M:%S"))
PY
)"

query="SELECT id, name, host, status, updated FROM systems WHERE status != 'up' AND datetime(updated) <= datetime('${cutoff}') ORDER BY updated;"
targets="$(
  docker run --rm -v "${volume}:/data" alpine sh -lc \
    "apk add --no-cache sqlite >/dev/null && sqlite3 -tabs /data/data.db \"${query}\""
)"

if [ -z "$targets" ]; then
  printf 'No matching systems found.\n'
  exit 0
fi

printf 'Matching systems:\n'
printf '%s\n' "$targets" | python3 - <<'PY'
import sys

for line in sys.stdin:
    system_id, name, host, status, updated = line.rstrip("\n").split("\t")
    if not name:
        name = "(no-name)"
    print(f"- {name} | host={host} | status={status} | updated={updated} | id={system_id}")
PY

if [ "$apply" != "1" ]; then
  printf '\nDry run only. Re-run with --apply to delete.\n'
  exit 0
fi

printf '\nDeleting matched systems...\n'
while IFS="$(printf '\t')" read -r system_id _name _host _status _updated; do
  docker run --rm -v "${volume}:/data" alpine sh -lc \
    "apk add --no-cache sqlite >/dev/null && sqlite3 /data/data.db \"DELETE FROM systems WHERE id = '${system_id}';\""
  printf 'Deleted %s\n' "$system_id"
done <<EOF
$targets
EOF

printf 'Done.\n'
