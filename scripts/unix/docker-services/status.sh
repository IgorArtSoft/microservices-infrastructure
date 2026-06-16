#!/usr/bin/env bash
set -euo pipefail

echo "Docker containers:"
docker ps

echo ""
echo "Kafka topics:"
if docker ps --format '{{.Names}}' | grep -q '^kafka$'; then
  docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
else
  echo "Kafka container is not running."
fi

echo ""
echo "HTTP endpoints:"

check_url() {
  local name="$1"
  local url="$2"

  if command -v curl >/dev/null 2>&1; then
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "$name is responding: $url"
    else
      echo "$name is not responding: $url"
    fi
  else
    echo "curl is not installed. Skipping check for $name."
  fi
}

check_url "Kafka UI" "http://localhost:8085"
check_url "order-service health" "http://localhost:8081/actuator/health"
check_url "payment-service health" "http://localhost:8082/actuator/health"