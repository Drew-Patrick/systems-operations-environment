# 002: SSH to backup on port 2222 rejected by host firewall

**Date:** 2026-10-14 (UTC)
**Machine(s):** backup (symptom seen from app)
**Severity:** (no remote access)

## Symptom
From app, `ssh backup hostname` returned
`ssh: connect to host 10.42.20.10 port 2222: No route to host`.
Expected: `backup`. sshd was confirmed running on backup (incident 001 had just
been resolved), so this was not the same failure.
Cause of the break (planned): `sudo firewall-cmd --remove-port=2222/tcp` on backup
(live config only; saved config untouched).

## Checked
- From app: `nc -zv 10.42.20.10 2222` returned
  `failed: No route to host`. Same answer as ssh, so not an SSH-specific problem.
- On backup: `sudo ss -tlnp | grep sshd` showed sshd listening on 2222 and 22.
  The service was fine.
- On backup: `sudo firewall-cmd --list-ports` printed nothing. 2222/tcp was no
  longer in the allowed list.
- On backup: `sudo timeout 15 tcpdump -ni enp0s8 port 2222` while app retried.
  Captured two packets, both `10.42.10.10 > 10.42.20.10 port 2222, Flags [S]`,
  and nothing back. The connection attempts reached backup's network card;
  backup did not answer on that port.

## Cause
firewalld on backup no longer allowed 2222/tcp. Packets arrived at the host
(tcpdump saw the SYNs) and were rejected by the host firewall before reaching
sshd. firewalld's default reject sends an ICMP "host prohibited" message, which
the client reports as "No route to host".

## Fix
On backup: `sudo firewall-cmd --reload`, which reapplied the saved config
(2222/tcp was still present there).

## Verified
- On backup: `sudo firewall-cmd --list-ports` printed `2222/tcp`.
- From app: `ssh backup hostname` printed `backup`.

## Follow-up
"No route to host" to a host that answers ping is a firewall reject, not a
routing problem. tcpdump on the target settles where the block is: SYNs
arriving with no reply means the block is on this host; no SYNs at all means
the block is upstream. Check `firewall-cmd --list-ports` and
`--list-services` before involving the network team.