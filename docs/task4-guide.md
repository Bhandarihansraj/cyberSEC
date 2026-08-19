# Practical Guide — Task 4 (Brute Force)

Repo: https://github.com/Bhandarihansraj/cyberSEC

### Setup
1. DVWA → **DVWA Security** → set level → Submit
2. Run: `./tasks/task4_bruteforce_burp/run.sh start` (confirms DVWA up, prints checklist)
3. Left menu → **Brute Force**

### Wordlists (ready-made files in the repo)
```
tasks/task4_bruteforce_burp/wordlists/usernames.txt
tasks/task4_bruteforce_burp/wordlists/passwords.txt
```
Load these directly as Payload set 1 / set 2 in Burp Intruder (Payloads tab → Load). `admin`/`password` is included in both — DVWA's real default creds — so a successful hit is guaranteed to show up in results.

---

## LOW — no protection

1. Submit any username/password once on the Brute Force form
2. Burp → Proxy → Intercept ON → resend the form → capture the GET request
   (`http://.../vulnerabilities/brute/?username=X&password=Y&Login=Login`)
3. Right-click → **Send to Intruder**
4. **Positions** tab: Clear §§, wrap only the `username` and `password` values:
   `username=§X§&password=§Y§`
5. Attack type: **Cluster Bomb**
6. **Payloads** tab: Payload set 1 = usernames.txt, Payload set 2 = passwords.txt
7. Start attack → sort results by **Length** (or Status) — the correct pair returns a longer/different response than the "incorrect" failures

---

## MEDIUM — Burp + slower (time-based defense)

Server adds `sleep(2)` after every failed login — same request format as Low, but the attack takes noticeably longer per request.

1. Same Intruder setup as Low (Cluster Bomb, username + password positions)
2. **Options** tab → reduce **Number of threads** (e.g. 1-2) — more threads won't beat a server-side sleep, they'll just queue up
3. Expect ~2 seconds per attempt minimum — for a small test wordlist this is fine; for large lists this is the whole point of the defense (rate-limiting)
4. Same result sorting (Length/Status) to spot the valid pair

---

## HIGH — anti-CSRF token, needs session handling

Each page load generates a new `user_token` hidden field; a request with a stale token is rejected — so you can't just replay Low/Medium's static Intruder attack.

1. In Burp: **Settings → Sessions → Session Handling Rules → Add**
2. Scope: tools = Intruder, URL = your DVWA host
3. Rule actions → **Add** → **Run a macro**
4. Create the macro: record one request to the Brute Force page (GET `/vulnerabilities/brute/`) — this is what fetches a fresh token before each Intruder request
5. In the macro config, click **Configure item** on that request → under **Custom parameter locations**, extract `user_token` from the response body (it's in a hidden input `name="user_token" value="..."`)
6. Back in the rule: under **Parameter updating**, tell it to update the `user_token` parameter value using the token grabbed from the macro, before every Intruder request
7. Now go to Intruder: Positions tab, wrap `username`, `password`, **and** `user_token` (the token position value doesn't matter — the session rule overwrites it): 
   `username=§X§&password=§Y§&user_token=§placeholder§`
8. Attack type: **Cluster Bomb** (username × password only — token payload set left empty/single dummy value since the rule replaces it)
9. Start attack — Burp fetches a fresh token via the macro before each request automatically, avoiding the "invalid token" rejection

---

## Quick reference

| Level  | Extra step vs Low               | Key setting |
|--------|----------------------------------|-------------|
| Low    | —                                 | Cluster Bomb, username + password |
| Medium | Reduce Intruder threads            | Same positions, expect ~2s/request delay |
| High   | Session Handling macro for `user_token` | Macro fetches fresh token before every request |

**Tell valid creds from noise:** sort Intruder results by response **Length** — failed logins all return the same length; the successful one stands out.
