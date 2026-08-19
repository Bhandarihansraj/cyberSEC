# cyberSEC
Repo: https://github.com/Bhandarihansraj/cyberSEC

Menu-driven Docker automation for Cloud & Web App Security lab tasks.
Every task runs as an isolated, independent operation — start/stop from one menu.

## Requirements
- Docker + Docker Compose plugin
- Nothing else — no manual Apache/MySQL/PHP setup needed

## Quick setup (fresh Kali)
Bootstraps everything in one shot — Docker, Burp check, repo clone, Python deps:
```bash
chmod +x setup.sh && ./setup.sh
```
This installs Docker Engine + Compose plugin (if missing), verifies Burp Suite,
clones/updates the repo into `~/cyberSEC`, makes all task scripts executable,
and installs the automation scripts' Python dependencies.
If Docker was just installed, run `newgrp docker` once (or log out/in) so
your user's new group membership takes effect.

## Usage
```bash
git clone https://github.com/Bhandarihansraj/cyberSEC.git
cd cyberSEC
chmod +x menu.sh tasks/*/run.sh
./menu.sh
```
Pick a task number, then `s` to start or `x` to stop.

Or run any task directly:
```bash
./tasks/task2_dvwa_setup/run.sh start
./tasks/task3_sql_injection/run.sh start
```

## Tasks
1. **task1_cloud_models** — Docker demo of IaaS (raw container), PaaS
   (runtime-managed app), SaaS (hosted app pointer).
2. **task2_dvwa_setup** — brings up DVWA (`vulnerables/web-dvwa`) at
   `http://127.0.0.1:4280` via Docker Compose.
3. **task3_sql_injection** — ensures DVWA is up, prints the Low/Medium/High
   payload checklist (exploitation itself is manual, in DVWA's UI).
4. **task4_bruteforce_burp** — ensures DVWA is up, prints the Burp Intruder
   Cluster Bomb setup steps.
5. **task5_file_upload** — ensures DVWA is up, prints the Low/Medium/High
   upload-bypass checklist.

Tasks 3–5 auto-start DVWA if it isn't already running (`tasks/lib.sh`).

## Automated exploitation (Task 3/4/5, all levels, no Burp/browser needed)
Scripts craft raw HTTP requests directly (login, set security level, attack) —
no proxy or manual interception required.

```bash
pip install -r tasks/automation/requirements.txt --break-system-packages

python3 tasks/task3_sql_injection/automation/sqli_auto.py all      # SQLi, Low/Med/High
python3 tasks/task4_bruteforce_burp/automation/bruteforce_auto.py all   # Brute force, Low/Med/High
python3 tasks/task5_file_upload/automation/upload_auto.py all      # Upload bypass, Low/Med/High
```
Pass `low`, `medium`, or `high` instead of `all` to run a single level.
DVWA must be running first (`./tasks/task2_dvwa_setup/run.sh start`).

## Task guides
Full step-by-step + payloads for each task are in `docs/`:
- `docs/task2-guide.md` — DVWA setup (start/stop, first-time browser setup)
- `docs/task3-guide.md` — SQL Injection (Low/Medium/High)
- `docs/task4-guide.md` — Brute Force (Low/Medium/High, Burp Intruder)
- `docs/task5-guide.md` — File Upload (Low/Medium/High) + upload directory locations
- `docs/docker-commands.md` — Docker command reference shared across Task 2-5 (exec, logs, cp, cleanup)

Open the guide for the task you're working on and follow it top to bottom —
each one is self-contained (setup step, payloads per level, quick reference
table at the end).

## Security notes
- DVWA port is bound to `127.0.0.1` only — never expose it on `0.0.0.0` or a
  public interface; it is intentionally vulnerable software.
- Run only on an isolated/lab machine or VM, never on a production host or
  shared network.
- `stop` removes containers/networks — no persistent data kept between runs.
- Use only against your own local instance, for coursework/practice.
