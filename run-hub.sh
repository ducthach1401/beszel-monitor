#!/usr/bin/env bash
set -eu

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi
docker-compose -f docker-compose.hub.yml down
docker-compose -f docker-compose.hub.yml up -d
