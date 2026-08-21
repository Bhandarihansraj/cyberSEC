#!/usr/bin/env bash
# Task 6: John the Ripper — Single Crack Mode + Wordlist Mode.
# Runs directly on Kali (john + openssl are already installed there,
# no Docker container needed for this one).
set -euo pipefail
ACTION="${1:-start}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HASH_FILE="$DIR/password.txt"
WORDLIST="/usr/share/wordlists/rockyou.txt"

require_john() {
    command -v john >/dev/null 2>&1 || { echo "John the Ripper not found. Install: sudo apt install john"; exit 1; }
}

make_sample_hash() {
    if [ ! -f "$HASH_FILE" ]; then
        # demo user "user" with password "password123" (SHA-512 crypt hash)
        echo "user:$(openssl passwd -6 -salt demo123 password123)" > "$HASH_FILE"
        echo "Sample hash created at $HASH_FILE (user:password123)"
    fi
}

case "$ACTION" in
    start)
        require_john
        make_sample_hash

        echo "== Part A: Single Crack Mode =="
        john --single "$HASH_FILE" || true
        john --show "$HASH_FILE" || true

        echo
        echo "== Part B: Wordlist Mode (rockyou.txt) =="
        if [ ! -f "$WORDLIST" ]; then
            if [ -f "${WORDLIST}.gz" ]; then
                echo "Extracting rockyou.txt.gz..."
                sudo gzip -dk "${WORDLIST}.gz"
            else
                echo "rockyou.txt not found at $WORDLIST — skipping wordlist mode."
                exit 0
            fi
        fi
        john --wordlist="$WORDLIST" "$HASH_FILE" || true
        john --show "$HASH_FILE" || true
        ;;
    stop)
        rm -f "$HASH_FILE" "$DIR"/*.pot 2>/dev/null || true
        echo "Sample hash + John's pot file cleared."
        ;;
    *)
        echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
