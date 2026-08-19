"""
Shared DVWA session handler — login, security-level switching, token extraction.
Reused by sqli_auto.py, bruteforce_auto.py, upload_auto.py.
"""
import re
import requests

TOKEN_RE = re.compile(r"user_token'\s*value='([a-f0-9]+)'")


class DVWAClient:
    def __init__(self, base_url="http://127.0.0.1:4280", user="admin", password="password"):
        self.base = base_url.rstrip("/")
        self.user = user
        self.password = password
        self.s = requests.Session()

    def _extract_token(self, html: str) -> str:
        m = TOKEN_RE.search(html)
        return m.group(1) if m else ""

    def login(self):
        r = self.s.get(f"{self.base}/login.php")
        token = self._extract_token(r.text)
        self.s.post(
            f"{self.base}/login.php",
            data={"username": self.user, "password": self.password,
                  "Login": "Login", "user_token": token},
        )

    def set_security(self, level: str):
        """level: low | medium | high"""
        r = self.s.get(f"{self.base}/security.php")
        token = self._extract_token(r.text)
        self.s.post(
            f"{self.base}/security.php",
            data={"security": level, "seclev_submit": "Submit", "user_token": token},
        )

    def fresh_token(self, path: str) -> str:
        """Fetch a fresh page and pull its current user_token (needed for High-level requests)."""
        r = self.s.get(f"{self.base}{path}")
        return self._extract_token(r.text)
