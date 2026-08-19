#!/usr/bin/env bash
# Practical 2: DVWA setup/teardown via Docker (replaces manual LAMP install).
set -euo pipefail
ACTION="${1:-start}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$ACTION" in
    start)
        docker compose -f "$DIR/docker-compose.yml" up -d
        echo
        echo "DVWA starting -> http://127.0.0.1:4280/setup.php"
        echo "1. Click 'Create / Reset Database'"
        echo "2. Login: admin / password"
        echo "3. Go to 'DVWA Security' tab to set Low/Medium/High"
        echo
        echo "SECURITY: bound to 127.0.0.1 only. Do NOT expose this port to the network/internet."
        ;;
    stop)
        docker compose -f "$DIR/docker-compose.yml" down
        echo "DVWA stopped and removed."
        ;;
    *)
        echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
