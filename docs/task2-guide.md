# Practical Guide — Task 2 (DVWA Setup)

Repo: https://github.com/Bhandarihansraj/cyberSEC

### Start
```bash
cd cyberSEC
./tasks/task2_dvwa_setup/run.sh start
```
Or via menu: `./menu.sh` → select `2` → `s`

### First-time browser setup
1. Open `http://127.0.0.1:4280`
2. Login: `admin` / `password`
3. Left menu → **Create / Reset Database** → wait for success message
4. Login again with same credentials

### Stop
```bash
./tasks/task2_dvwa_setup/run.sh stop
```
Removes the container + network. No data is kept between runs — you'll need to Create/Reset Database again next start.

### Security reminder
Bound to `127.0.0.1:4280` only. Never forward this port externally — DVWA is intentionally vulnerable.
