#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORKSPACE_ROOT="$(cd "$INFRA_ROOT/.." && pwd)"

build_service() {
  local service_name="$1"
  local service_dir="$WORKSPACE_ROOT/$service_name"

  if [[ ! -d "$service_dir" ]]; then
    echo "Skipping $service_name. Directory not found: $service_dir"
    return
  fi

  echo "Building $service_name..."
  cd "$service_dir"

  if [[ -x "./mvnw" ]]; then
    ./mvnw -DskipTests clean package
  else
    mvn -DskipTests clean package
  fi

  echo "$service_name build completed."
  echo ""
}

build_service "order-service"
build_service "payment-service"
build_service "customer-service"

echo "Compilation completed."