#!/usr/bin/env bash
# Menu-driven launcher — every task runs as an isolated Docker operation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_docker() {
    command -v docker >/dev/null 2>&1 || { echo "Docker not found. Install Docker first."; exit 1; }
}

TASKS=(
    "task1_cloud_models:Cloud Service Models (IaaS/PaaS/SaaS)"
    "task2_dvwa_setup:Start/Stop DVWA"
    "task3_sql_injection:SQL Injection checklist"
    "task4_bruteforce_burp:Brute Force (Burp Intruder) checklist"
    "task5_file_upload:File Upload checklist"
)

menu() {
    clear
    echo "========================================"
    echo " cyberSEC"
    echo "========================================"
    local i=1
    for t in "${TASKS[@]}"; do
        echo " $i) ${t#*:}"
        ((i++))
    done
    echo " 0) Exit"
    echo "----------------------------------------"
}

require_docker
while true; do
    menu
    read -rp "Select task [0-${#TASKS[@]}]: " choice
    if [[ "$choice" == "0" ]]; then exit 0; fi
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#TASKS[@]} )); then
        echo "Invalid choice"; sleep 1; continue
    fi
    dir="${TASKS[$((choice-1))]%%:*}"
    read -rp "Action - start(s) / stop(x): " act
    case "$act" in
        s) bash "$ROOT/tasks/$dir/run.sh" start ;;
        x) bash "$ROOT/tasks/$dir/run.sh" stop ;;
        *) echo "Invalid action" ;;
    esac
    read -rp "Press Enter to continue..." _
done
