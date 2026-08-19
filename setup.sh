#!/usr/bin/env bash
# cyberSEC bootstrap — fresh Kali box -> ready to run ./menu.sh
# Usage: chmod +x setup.sh && ./setup.sh
set -euo pipefail

REPO_URL="https://github.com/Bhandarihansraj/cyberSEC.git"
REPO_DIR="$HOME/cyberSEC"

log() { echo -e "\n[+] $*"; }
err() { echo -e "\n[!] $*" >&2; }

require_root_or_sudo() {
    if [[ $EUID -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
        err "Need root or sudo. Exiting."
        exit 1
    fi
}
SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

require_root_or_sudo

log "Updating apt package lists"
$SUDO apt-get update -y

log "Installing base tools (git, curl, python3, pip)"
$SUDO apt-get install -y --no-install-recommends \
    git curl ca-certificates python3 python3-pip python3-venv

# ---- Docker ----
if ! command -v docker >/dev/null 2>&1; then
    log "Docker not found — installing Docker Engine + Compose plugin"
    # Kali is Debian-based; use Docker's official Debian repo
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
        $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

    ARCH="$(dpkg --print-architecture)"
    CODENAME="bookworm"  # Kali tracks Debian testing/bookworm packages for Docker's repo
    echo \
        "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${CODENAME} stable" | \
        $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

    $SUDO apt-get update -y
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
else
    log "Docker already installed — skipping"
fi

log "Enabling and starting Docker service"
$SUDO systemctl enable --now docker || $SUDO service docker start || true

if ! groups "$USER" | grep -q docker; then
    log "Adding $USER to docker group (log out/in or 'newgrp docker' to apply)"
    $SUDO usermod -aG docker "$USER"
fi

# ---- Burp Suite (usually preinstalled on Kali; verify) ----
if command -v burpsuite >/dev/null 2>&1; then
    log "Burp Suite already present"
else
    log "Burp Suite not found — installing via apt (Community edition)"
    $SUDO apt-get install -y burpsuite || \
        err "burpsuite package unavailable; install manually from portswigger.net if needed for manual/task4 walkthroughs"
fi

# ---- Clone / update repo ----
if [[ -d "$REPO_DIR/.git" ]]; then
    log "Repo already cloned at $REPO_DIR — pulling latest"
    git -C "$REPO_DIR" pull --ff-only
else
    log "Cloning cyberSEC into $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

log "Making task/menu scripts executable"
chmod +x menu.sh
find tasks -name "run.sh" -exec chmod +x {} \;

# ---- Python deps for automation scripts (sqli/bruteforce/upload) ----
if [[ -f "tasks/automation/requirements.txt" ]]; then
    log "Installing Python automation deps (requests, etc.)"
    pip3 install -r tasks/automation/requirements.txt --break-system-packages
else
    log "No tasks/automation/requirements.txt found — installing 'requests' directly"
    pip3 install requests --break-system-packages
fi

log "Done."
echo "----------------------------------------------------------"
echo " Repo:        $REPO_DIR"
echo " Run:         cd $REPO_DIR && ./menu.sh"
echo " Note:        if 'docker' permission denied, run: newgrp docker"
echo "              (or log out/in once for the group change to apply)"
echo "----------------------------------------------------------"
