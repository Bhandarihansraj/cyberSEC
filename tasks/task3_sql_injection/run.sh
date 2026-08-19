#!/usr/bin/env bash
# Task 3: SQL Injection (Low/Medium/High). Exploitation itself is manual in
# DVWA's UI + Burp — this only guarantees the target is up and prints the
# payload/steps checklist so nothing has to be looked up mid-practice.
set -euo pipefail
ACTION="${1:-start}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/tasks/lib.sh"

case "$ACTION" in
    start)
        ensure_dvwa
        cat <<'EOF'

== SQL Injection checklist (DVWA -> SQL Injection tab) ==
LOW:    1' OR '1'='1
        ORDER BY <n>-- to find column count, then UNION SELECT ...
MEDIUM: dropdown -> intercept in Burp -> numeric UNION SELECT (no quotes)
HIGH:   quotes stripped + LIMIT 1 -> terminate with -- or #, then numeric
        UNION SELECT, submit with valid session cookie

Set security level: DVWA Security tab -> Low/Medium/High
EOF
        ;;
    stop)
        echo "Task 3 has no running state of its own — stop DVWA via task2 if done."
        ;;
    *)
        echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
