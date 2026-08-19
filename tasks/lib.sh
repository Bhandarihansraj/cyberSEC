#!/usr/bin/env bash
# Shared helper: ensure DVWA container is running before a task that uses it.
ensure_dvwa() {
    if [ "$(docker ps -q -f name=dvwa-lab)" = "" ]; then
        echo "DVWA not running — starting it first..."
        bash "$ROOT/tasks/task2_dvwa_setup/run.sh" start
    else
        echo "DVWA already running at http://127.0.0.1:4280"
    fi
}
