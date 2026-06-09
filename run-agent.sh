#!/usr/bin/env bash
set -eu

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

get_system_name() {
  if command -v tailscale >/dev/null 2>&1; then
    local tailscale_name
    tailscale_name="$(
      tailscale status --json 2>/dev/null \
      | python3 -c 'import json,sys; print(json.load(sys.stdin).get("Self", {}).get("HostName", ""))' 2>/dev/null
    )"
    if [ -n "$tailscale_name" ]; then
      printf '%s\n' "$tailscale_name"
      return 0
    fi
  fi

  hostname
}

export HUB_URL="${HUB_URL:?HUB_URL is required in .env}"
export AGENT_TOKEN="${AGENT_TOKEN:?AGENT_TOKEN is required in .env}"
export AGENT_KEY="${AGENT_KEY:?AGENT_KEY is required in .env}"
export SYSTEM_NAME="${SYSTEM_NAME:-$(get_system_name)}"

docker-compose -f docker-compose.agent.yml down
docker-compose -f docker-compose.agent.yml up -d
