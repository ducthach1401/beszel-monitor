#!/usr/bin/env bash
set -eu

repo_dir="$(cd "$(dirname "$0")" && pwd)"
cron_line="0 9 * * * cd ${repo_dir} && /bin/bash ${repo_dir}/cleanup-systems.sh --apply >> ${repo_dir}/cleanup-systems.log 2>&1"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

crontab -l 2>/dev/null | grep -Fv "${repo_dir}/cleanup-systems.sh --apply" > "$tmp_file" || true
printf '%s\n' "$cron_line" >> "$tmp_file"
crontab "$tmp_file"

printf 'Installed cleanup cron at 09:00 daily.\n'
