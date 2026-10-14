# 001: SSH to backup on port 2222 refused

**Date:** 2026-10-14 (UTC)
**Machine(s):** backup (symptom seen from app)
**Severity:** high (no remote access to the host)

## Symptom
From app, `ssh backup hostname` returned immediately with
`ssh: connect to host 10.42.20.10 port 2222: Connection refused`.
Expected: `backup` printed with no password prompt, as on previous runs.
Cause of the break (planned): `sudo systemctl stop sshd` on backup.

## Checked
- From app: `nc -zv 10.42.20.10 2222` returned
  `connect to 10.42.20.10 port 2222 (tcp) failed: Connection refused`.
  "Refused" means the host answered and said nothing is listening there,
  so the host is reachable and the network path is fine.
- On backup: `sudo ss -tlnp | grep sshd` printed nothing. No sshd process
  was listening on any port.

## Cause
The SSH daemon (sshd) was not running on backup. With no process listening on
port 2222, the kernel answered the connection attempt with a TCP reset, which
the client reports as "Connection refused".

## Fix
On backup: `sudo systemctl start sshd`.

## Verified
- On backup: `sudo ss -tlnp | grep sshd` showed four LISTEN lines, for ports
  2222 and 22 on IPv4 and IPv6.
- From app: `ssh backup hostname` printed `backup`.

## Follow-up
"Connection refused" means reached the machine, nothing listening. First check
is `ss -tlnp` on the target for the expected port, then `systemctl status` for
the service that should own it. Do not start with the firewall or the network;
a refused connection has already proven both are passing traffic.