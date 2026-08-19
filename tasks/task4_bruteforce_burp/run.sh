#!/usr/bin/env bash
# Task 4: Brute force via Burp Intruder (Cluster Bomb). Attack itself runs
# inside Burp GUI — this ensures the target is up and prints the setup steps.
set -euo pipefail
ACTION="${1:-start}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/tasks/lib.sh"

case "$ACTION" in
    start)
        ensure_dvwa
        cat <<'EOF'

== Brute Force checklist (DVWA -> Brute Force tab) ==
1. Browser proxy -> 127.0.0.1:8080 (Burp), Intercept ON
2. Submit any username/password on the Brute Force form
3. In Burp Proxy: right-click captured request -> Send to Intruder
4. Positions tab: clear markers, add §...§ around username value and
   password value only
5. Attack type: Cluster Bomb
6. Payloads tab: set 1 = username wordlist, set 2 = password wordlist
7. (Optional) Grep-Match rule for "incorrect" to spot failures fast
8. Start attack -> sort results by Length/Status -> odd-one-out = valid pair
EOF
        ;;
    stop)
        echo "Task 4 has no running state of its own — stop DVWA via task2 if done."
        ;;
    *)
        echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
