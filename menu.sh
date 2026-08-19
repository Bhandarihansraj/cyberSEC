#!/usr/bin/env bash
# cyberSEC — Menu-driven launcher
# Every task runs as an isolated Docker operation.
# Tasks 3/4/5 can additionally run their automation scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_docker() {
    command -v docker >/dev/null 2>&1 || {
        echo "Docker not found. Install Docker first."
        exit 1
    }
}

TASKS=(
    "task1_cloud_models:Cloud Service Models (IaaS/PaaS/SaaS)"
    "task2_dvwa_setup:Start/Stop DVWA"
    "task3_sql_injection:SQL Injection"
    "task4_bruteforce_burp:Brute Force (Burp Intruder)"
    "task5_file_upload:File Upload"
)

automation_script() {
    case "$1" in
        task3_sql_injection)   echo "task3_sql_injection/automation/sqli_auto.py" ;;
        task4_bruteforce_burp) echo "task4_bruteforce_burp/automation/bruteforce_auto.py" ;;
        task5_file_upload)     echo "task5_file_upload/automation/upload_auto.py" ;;
        *) echo "" ;;
    esac
}

pause_menu() {
    echo
    read -rp "Press Enter to continue..." _
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

run_task() {
    local dir="$1"
    local action="$2"
    local runner="$ROOT/tasks/$dir/run.sh"

    if [[ ! -f "$runner" ]]; then
        echo "Error: task runner not found:"
        echo "  $runner"
        return 1
    fi

    chmod +x "$runner" 2>/dev/null || true
    bash "$runner" "$action"
}

run_automation() {
    local dir="$1"
    local script
    local level

    script="$(automation_script "$dir")"

    if [[ -z "$script" ]]; then
        echo "No automation script for this task."
        return 1
    fi

    if [[ ! -f "$ROOT/tasks/$script" ]]; then
        echo "Error: automation script not found:"
        echo "  $ROOT/tasks/$script"
        return 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo "Python3 not found. Install Python3 first."
        return 1
    fi

    read -rp "Level - low/medium/high/all: " level

    case "$level" in
        low|medium|high|all) ;;
        *)
            echo "Invalid level. Use: low, medium, high, or all."
            return 1
            ;;
    esac

    echo
    echo "---------------- live output ----------------"
    python3 -u "$ROOT/tasks/$script" "$level"
    echo "-----------------------------------------------"
}

require_docker

while true; do
    menu

    read -rp "Select task [0-${#TASKS[@]}]: " choice

    if [[ "$choice" == "0" ]]; then
        echo "Exiting cyberSEC..."
        exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||        (( choice < 1 || choice > ${#TASKS[@]} )); then
        echo "Invalid choice."
        sleep 1
        continue
    fi

    dir="${TASKS[$((choice-1))]%%:*}"
    has_auto="$(automation_script "$dir")"

    echo
    if [[ -n "$has_auto" ]]; then
        echo "Action:"
        echo " s) Start"
        echo " x) Stop"
        echo " a) Automate"
        echo
        read -rp "Select action [s/x/a]: " act
    else
        echo "Action:"
        echo " s) Start"
        echo " x) Stop"
        echo
        read -rp "Select action [s/x]: " act
    fi

    echo

    case "$act" in
        s) run_task "$dir" start ;;
        x) run_task "$dir" stop ;;
        a)
            if [[ -n "$has_auto" ]]; then
                run_automation "$dir"
            else
                echo "Automation is not available for this task."
            fi
            ;;
        *) echo "Invalid action." ;;
    esac

    pause_menu
done