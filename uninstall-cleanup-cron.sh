#!/usr/bin/env bash
set -eu

repo_dir="$(cd "$(dirname "$0")" && pwd)"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

crontab -l 2>/dev/null | grep -Fv "${repo_dir}/cleanup-systems.sh --apply" > "$tmp_file" || true

if [ ! -s "$tmp_file" ]; then
  crontab -r 2>/dev/null || true
else
  crontab "$tmp_file"
fi

printf 'Removed cleanup cron.\n'
