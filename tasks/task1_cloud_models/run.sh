#!/usr/bin/env bash
# Practical 1: Cloud Service Models demo using Docker instead of a full VM.
set -euo pipefail
ACTION="${1:-start}"
NET="cloud-demo-net"

start() {
    docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET" >/dev/null

    echo "[IaaS] Raw container = self-managed OS (user owns everything above hardware)."
    docker run -d --name iaas-demo --network "$NET" ubuntu:22.04 sleep infinity >/dev/null

    echo "[PaaS] Deploying app; only code is pushed, runtime/OS managed by the container."
    docker run -d --name paas-demo --network "$NET" \
        -p 127.0.0.1:5001:5000 python:3.11-slim \
        python3 -c "
from http.server import HTTPServer, BaseHTTPRequestHandler
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.end_headers()
        self.wfile.write(b'PaaS demo app running')
HTTPServer(('0.0.0.0', 5000), H).serve_forever()
" >/dev/null

    echo "[SaaS] Fully hosted app, nothing to run locally — e.g. open https://docs.google.com in browser."
    echo
    echo "IaaS shell : docker exec -it iaas-demo bash"
    echo "PaaS app   : http://127.0.0.1:5001"
}

stop() {
    docker rm -f iaas-demo paas-demo >/dev/null 2>&1 || true
    docker network rm "$NET" >/dev/null 2>&1 || true
    echo "Practical 1 containers removed."
}

case "$ACTION" in
    start) start ;;
    stop)  stop ;;
    *) echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
