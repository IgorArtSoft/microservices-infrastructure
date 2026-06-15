#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

COMPOSE_INFRA="$INFRA_ROOT/compose/docker-compose.infra.yml"
COMPOSE_SERVICES="$INFRA_ROOT/compose/docker-compose.services.yml"

if [[ ! -f "$COMPOSE_INFRA" ]]; then
  echo "Compose infrastructure file was not found: $COMPOSE_INFRA"
  exit 1
fi

COMPOSE_ARGS=(-f "$COMPOSE_INFRA")

if [[ -f "$COMPOSE_SERVICES" ]]; then
  COMPOSE_ARGS+=(-f "$COMPOSE_SERVICES")
fi

echo "Stopping Docker environment..."
docker compose "${COMPOSE_ARGS[@]}" down --remove-orphans

echo "Docker environment stopped."