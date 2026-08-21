#!/usr/bin/env bash
# Menu-driven launcher — every task runs as an isolated Docker operation,
# and task 3/4/5 also offer automated exploitation with live output.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_docker() {
    command -v docker >/dev/null 2>&1 || { echo "Docker not found. Install Docker first."; exit 1; }
}

TASKS=(
    "task1_cloud_models:Cloud Service Models (IaaS/PaaS/SaaS)"
    "task2_dvwa_setup:Start/Stop DVWA"
    "task3_sql_injection:SQL Injection"
    "task4_bruteforce_burp:Brute Force (Burp Intruder)"
    "task5_file_upload:File Upload"
    "task6_password_cracking:Password Cracking (John the Ripper)"
    "task7_metasploit:Metasploit (vsftpd 2.3.4 exploit)"
)

# Task -> its automation script (only 3/4/5 have one)
automation_script() {
    case "$1" in
        task3_sql_injection)   echo "task3_sql_injection/automation/sqli_auto.py" ;;
        task4_bruteforce_burp) echo "task4_bruteforce_burp/automation/bruteforce_auto.py" ;;
        task5_file_upload)     echo "task5_file_upload/automation/upload_auto.py" ;;
        *) echo "" ;;
    esac
}

menu() {
    clear
    echo "========================================"
    echo " cyberSEC — Task Automation"
    echo "========================================"
    local i=1
    for t in "${TASKS[@]}"; do
        echo " $i) ${t#*:}"
        ((i++))
    done
    echo " 0) Exit"
    echo "----------------------------------------"
}

run_automation() {
    local dir="$1" script
    script="$(automation_script "$dir")"
    if [[ -z "$script" ]]; then
        echo "No automation script for this task."
        return
    fi
    read -rp "Level - low/medium/high/all: " level
    echo "---------------- live output ----------------"
    python3 -u "$ROOT/tasks/$script" "$level"
    echo "-----------------------------------------------"
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
    has_auto="$(automation_script "$dir")"
    if [[ -n "$has_auto" ]]; then
        read -rp "Action - start(s) / stop(x) / automate(a): " act
    else
        read -rp "Action - start(s) / stop(x): " act
    fi
    case "$act" in
        s) bash "$ROOT/tasks/$dir/run.sh" start ;;
        x) bash "$ROOT/tasks/$dir/run.sh" stop ;;
        a) [[ -n "$has_auto" ]] && run_automation "$dir" || echo "Invalid action" ;;
        *) echo "Invalid action" ;;
    esac
    read -rp "Press Enter to continue..." _
done
