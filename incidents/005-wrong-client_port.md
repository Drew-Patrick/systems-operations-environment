# 005: SSH to backup fails because the client config has the wrong port

**Date:** 2026-10-14 (UTC)
**Machine(s):** app (client side); backup unchanged
**Severity:** medium (one client cannot connect; server healthy).

## Symptom
From app, `ssh backup hostname` returned
`ssh: connect to host 10.42.20.10 port 2223: No route to host`.
Expected: `backup`. The message looks like a network or firewall problem on the server
side.
Cause of the break (planned): on app, `sed -i 's/Port 2222/Port 2223/' ~/.ssh/config`,
changing the shortcut's port from 2222 to 2223.

## Checked
- On app: `cat ~/.ssh/config` showed `Port 2223` under `Host backup`.
- On app: `ssh -v backup hostname 2>&1 | grep -i connect` printed
  `debug1: Connecting to 10.42.20.10 [10.42.20.10] port 2223.` The client was knocking on
  port 2223, where nothing listens and which the firewall does not allow.
- On backup (not changed during this incident): sshd listens on 2222 and 22
  (`ss -tlnp`), and `firewall-cmd --list-ports` shows `2222/tcp`. Server side healthy.

## Cause
The client's own configuration pointed at the wrong port. backup's firewall rejected the
knock on 2223 (hence "No route to host"), but the server had done nothing wrong. The
error message described the symptom at the server without saying the request itself was
mis-addressed.

## Fix
On app: `sed -i 's/Port 2223/Port 2222/' ~/.ssh/config`.

## Verified
- From app: `ssh backup hostname` printed `backup`.

## Follow-up
Before escalating any "cannot reach server" report, confirm what the client is actually
trying to connect to. `ssh -v` (and the verbose flag on most tools) prints the exact
address and port in its first lines. A server-side error message does not prove the
server is at fault; it only proves the request reached something that said no.