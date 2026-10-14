# 006: scheduled backup fails because the private key file is too open

**Date:** 2026-10-14 (UTC)
**Machine(s):** app
**Severity:** high (backups silently stop until noticed).

## Symptom
Two symptoms, same cause.
- Interactive: from app, `ssh backup hostname` printed a banner
  `WARNING: UNPROTECTED PRIVATE KEY FILE!`, then
  `Permissions 0644 for '/home/vagrant/.ssh/id_ed25519' are too open.`,
  `This private key will be ignored.`, and fell back to a password prompt.
- Unattended: the next backup.timer run at 20:20:05 UTC failed. The journal showed
  `backup: start` with no `backup: ok`, and systemd reported
  `backup.service: Main process exited, code=exited, status=255/EXCEPTION` and
  `Failed to start backup.service`.
Expected: `backup` printed with no prompt; timer runs ending in `backup: ok`.
Cause of the break (planned): `chmod 644 ~/.ssh/id_ed25519` on app.

## Checked
- On app: `ls -l ~/.ssh/id_ed25519` showed `-rw-r--r--` (0644). SSH requires 0600.
- On app: `journalctl -u backup.service` for the failed run, read from the top of the
  block: `Permissions 0644 ... are too open` and `Load key ... bad permissions` (the key
  was refused), then `Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password)`
  (every login method failed, with no human present to type a password), then
  `rsync: connection unexpectedly closed` and `rsync error ... (code 255)` (rsync's
  transport, SSH, never came up), then systemd's `status=255`.

## Cause
The private key file was world-readable. SSH refuses to use a private key that other
users could read, so it ignored the key and had no other way to authenticate. The
interactive session fell back to a password prompt; the scheduled job had no one to
answer it, so SSH failed, rsync failed with exit 255, and `set -e` in the script passed
that code to systemd.

## Fix
On app: `chmod 600 ~/.ssh/id_ed25519`.

## Verified
- From app: `ssh backup hostname` printed `backup` with no banner and no prompt.
- On app: `sudo systemctl start backup.service` then `journalctl -u backup.service`
  showed `backup: start`, `backup: ok`, `Finished backup.service`.

## Follow-up
Private keys must be 0600 and the `.ssh` directory 0700; SSH enforces this and says so
plainly in the log. When a scheduled job fails, read its journal block from the oldest
line down: the alarm (systemd "Failed") is at the bottom, the cause is at the top.
Because the script exits non-zero on failure, the job reported failure instead of
silently doing nothing, which is the behavior to keep.