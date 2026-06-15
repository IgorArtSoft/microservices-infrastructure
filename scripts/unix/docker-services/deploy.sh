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
  echo "Using Dockerized microservices Compose file: $COMPOSE_SERVICES"
  COMPOSE_ARGS+=(-f "$COMPOSE_SERVICES")
else
  echo "compose/docker-compose.services.yml was not found."
  echo "Starting infrastructure only: Kafka, Kafka UI, MongoDB."
  echo "Dockerized Spring Boot services will not start until docker-compose.services.yml is added."
fi

echo "Starting Docker environment..."
docker compose "${COMPOSE_ARGS[@]}" up -d --build

echo ""
echo "Environment started."
echo "Kafka broker: localhost:9092"
echo "Kafka UI:     http://localhost:8085"
echo "MongoDB:      http://localhost:8084/"
echo "Order API:    http://localhost:8081"
echo "Payment API:  http://localhost:8082"
echo "Swagger:      http://localhost:8081/swagger-ui/index.html"