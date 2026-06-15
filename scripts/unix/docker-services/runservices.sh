#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "runservices.sh is kept as a legacy compatibility alias."
echo "Dockerized services are started by deploy.sh using Docker Compose."

"$SCRIPT_DIR/deploy.sh"