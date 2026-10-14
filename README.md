# systems-operations-environment

A small, rebuildable systems operations lab: three Linux VMs on two subnets with a
router between them, SSH on a non-standard port behind SELinux and a host firewall,
key-based access, an rsync backup on a systemd timer, and a set of incidents that were
broken on purpose, diagnosed, fixed, and written up.

Built in October 2026 as a hands-on study of the skills a production support / systems
operations role asks for: networking, Linux on two distributions, command-line
troubleshooting, scheduled jobs, log analysis, and clear incident records. Everything
here can be rebuilt from this repo with `vagrant up`.

## Layout

```
 Windows host (VirtualBox + Vagrant)
 ┌──────────────────────────────────────────────────────────────┐
 │                                                              │
 │   net10  10.42.10.0/24              net20  10.42.20.0/24     │
 │   ┌───────────┐         ┌──────────┐         ┌───────────┐   │
 │   │ app       │         │ router   │         │ backup    │   │
 │   │ Ubuntu 24 │ eth1    │ Ubuntu 24│   eth2  │ Rocky 9   │   │
 │   │ .10.10    ├─────────┤ .10.1    ├─────────┤ .20.10    │   │
 │   │           │   eth1  │  .20.1   │         │ sshd :2222│   │
 │   └───────────┘         └──────────┘         └───────────┘   │
 │        rsync every 5 min over ssh -p 2222  ───────────►      │
 └──────────────────────────────────────────────────────────────┘
```

- **router**: Ubuntu 24.04, `ip_forward` enabled, one door on each subnet.
- **app**: Ubuntu 24.04. Static route to net20 via netplan. Holds `/srv/data`. Runs
  `backup.timer`, which rsyncs to backup every 5 minutes and refuses to run if the
  destination is over 90% full.
- **backup**: Rocky Linux 9. Static route to net10 via NetworkManager. sshd on 2222 as
  well as 22, with the SELinux port label and firewalld rule to match. Receives into
  `/srv/backup`.

All of it is provisioned by the scripts in `provision/`. The SSH public key is handed
from app to backup through the shared folder during provisioning; no private key is in
this repo.

## Rebuild from nothing

```
vagrant up            # builds router, app, backup and runs provision/*.sh
vagrant ssh app -c "ping -c 3 10.42.20.10"            # ttl=63: through the router
vagrant ssh app -c "ssh backup hostname"               # key login on port 2222
vagrant ssh app -c "journalctl -u backup.service -n 5" # the timer's last run
vagrant provision     # safe to run again; every script is idempotent
```

## Incidents

Each one was induced deliberately, diagnosed with standard tools, fixed, and verified.
Every write-up quotes the real commands and output and follows `incidents/TEMPLATE.md`
(symptom, checked, cause, fix, verified, follow-up).

| # | Title | What it teaches |
|---|---|---|
| [001](incidents/001-ssh-refused.md) | SSH refused | "Connection refused" = reached the host, nothing listening. `ss -tlnp`. |
| [002](incidents/002-ssh-firewall.md) | SSH rejected by host firewall | "No route to host" from a live host = firewall reject. `tcpdump` shows SYNs arriving with no reply. |
| [003](incidents/003-route-removed.md) | Route removed | Silent loss: `ip route get` names the wrong gateway. |
| [004](incidents/004-wrong-subnet-mask.md) | Wrong subnet mask | Gateway reachable, next subnet "Host Unreachable", `ip neigh` FAILED: a /16 where a /24 belonged. |
| [005](incidents/005-wrong-client-port.md) | Wrong port in client config | Server healthy; `ssh -v` shows the client knocking on the wrong door. |
| [006](incidents/006-key-permissions.md) | Private key too open | Scheduled job fails; journal read oldest-line-first gives the cause. |
| [007](incidents/007-disk-full.md) | Destination disk full | `df -h` then `du -sh`; job now checks free space and aborts clearly. |
| [U01](incidents/U01-router-boot-timeout.md) | Vagrant boot timeout (unplanned) | Console check before rebooting: up-but-unreachable vs never-booted. |
| [U02](incidents/U02-app-provisioner-race.md) | Provisioner race (unplanned) | A check that races `netplan apply`; exit codes and `set -e`. |

## Scripts

| File | Purpose |
|---|---|
| `scripts/backup.sh` | rsync `/srv/data` to backup over SSH; aborts if destination over 90% full; logs start/ok with UTC timestamps. Run by `backup.timer`. |
| `scripts/logscan.py` | Summarize a service log: logins by user/source, failed attempts, distinct errors with counts. Reads `journalctl -o short-iso` or a syslog file. |
| `scripts/netcheck.ps1` | Windows/PowerShell network diagnostics: addresses, routes, DNS, ping, port check, trace, listening ports. |
| `scripts/users.ps1` | Windows local user administration end to end: create, group, disable, enable, remove, with proof after each step. |
| `scripts/commands.md` | Linux to PowerShell table for every command used in this repo. |
| `docs/where-logs-live.md` | Which log, which path, which command, on Ubuntu and on Rocky. |

## What is deliberately not here yet

The build plan (`PLAN.md`) continues with a deployable service with versioned releases
and rollback, deployment incidents, a Windows Server VM, and the tooling named in
exchange-operations job postings (ServiceNow records, alerting to PagerDuty, Rundeck,
a timed DR drill, multicast with gap detection, Ansible). Those are next, not done, and
this README will say so until they are.
