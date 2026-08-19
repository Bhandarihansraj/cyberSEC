#!/usr/bin/env bash
# Task 5: File Upload (Low/Medium/High). Ensures DVWA is up, prints steps.
set -euo pipefail
ACTION="${1:-start}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/tasks/lib.sh"

case "$ACTION" in
    start)
        ensure_dvwa
        cat <<'EOF'

== File Upload checklist (DVWA -> Upload tab) ==
LOW:    upload test.php directly -> browse to /hackable/uploads/test.php,
        confirm it executes
MEDIUM: server checks Content-Type header only -> intercept upload in Burp,
        change Content-Type to image/jpeg, keep .php content -> forward
HIGH:   extension + real image-header check -> build a polyglot: valid image
        bytes + appended <?php ... ?> -> save as shell.gif -> upload passes
        (execution needs a separate LFI point — shown conceptually only)

Set security level: DVWA Security tab -> Low/Medium/High
EOF
        ;;
    stop)
        echo "Task 5 has no running state of its own — stop DVWA via task2 if done."
        ;;
    *)
        echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
