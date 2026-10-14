# Where logs live

Every row was checked on this lab's machines (Ubuntu 24.04 on `router` and `app`,
Rocky Linux 9 on `backup`). "journal" means the systemd journal, read with `journalctl`.

## Service and system logs

| What | Ubuntu 24.04 | Rocky Linux 9 | Command |
|---|---|---|---|
| Any systemd service | journal | journal | `journalctl -u <service> -n 50` (add `sudo` on Rocky) |
| Follow a service live | journal | journal | `journalctl -u <service> -f` |
| Logins, sudo, SSH auth | journal and `/var/log/auth.log` | journal and `/var/log/secure` | `journalctl -u sshd` or `grep sshd <file>` |
| Boot and kernel messages | journal, `dmesg` | journal, `dmesg` | `journalctl -k`, `journalctl -b` |
| General system log | journal, `/var/log/syslog` | journal, `/var/log/messages` | `journalctl` |
| Package installs | `/var/log/apt/history.log`, `/var/log/dpkg.log` | `/var/log/dnf.log` | `cat` / `grep` |
| Scheduled jobs (timers) | journal (`-u <name>.service`) | journal | `systemctl list-timers`, then `journalctl -u <name>.service` |
| Cron jobs | journal, `/var/log/syslog` | journal, `/var/log/cron` | `journalctl -u cron` / `grep CRON` |
| Firewall | `journalctl -u ufw` (if used) | `journalctl -u firewalld` | |
| SELinux denials | not present | `/var/log/audit/audit.log` | `sudo ausearch -m AVC -ts recent` |
| Network config changes | `journalctl -u systemd-networkd` | `journalctl -u NetworkManager` | |
| Web server (nginx) | `/var/log/nginx/access.log`, `error.log` | same | `tail -f`, `scripts/logscan.py` |
| This lab's backup job | journal on `app`: `journalctl -u backup.service` | | `scripts/logscan.py` |

## How to read the journal

| Need | Command |
|---|---|
| Last 50 lines for one service | `journalctl -u sshd -n 50 --no-pager` |
| Since a time | `journalctl -u sshd --since "2026-10-14 20:00" ` |
| Only errors and worse | `journalctl -p err -b` |
| Full timestamps with year (for scripts) | `journalctl -u sshd -o short-iso` |
| Summarize | `journalctl -u sshd -o short-iso --no-pager \| python3 scripts/logscan.py` |

## Reading a failure block

Read from the oldest line of the block down. The alarm (`Failed to start ...`) is the
newest line; the cause is usually the oldest. Example from incident 006: the first line
is `Permissions 0644 ... are too open`, the last is `Failed to start backup.service`.

## Flavor notes

- Ubuntu's `vagrant` user can read the journal without `sudo`; Rocky's cannot
  (`No journal files were opened due to insufficient permissions`).
- Plain syslog files (`/var/log/secure`, `/var/log/auth.log`) have no year in their
  timestamps. Use `journalctl -o short-iso` when ordering matters.
- Rocky prints "N failed login attempts since the last successful login" at login.
  Ubuntu does not. Both record the same events.
