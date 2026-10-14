# U02: app provisioner failed on re-run

**Date:** 2026-10-14 (UTC)
**Machine(s):** app
**Severity:** low

## Symptom
Ran `vagrant provision` to re-run all three provisioning scripts. The app script
stopped after printing `app: routes:` and Vagrant reported:
"The SSH command responded with a non-zero exit status."
Expected: all three scripts run cleanly a second time (idempotent).

## Checked
- Read the provision output: last line printed was `app: routes:`, so the
  failing command is the next one in the script, `ip route | grep 10.42.20`.
- On app, by hand: `ip route | grep 10.42.20` showed
  `10.42.20.0/24 via 10.42.10.1 dev eth1 proto static`, and `echo $?` printed 0.
  So the route exists and grep finds it when run later.

## Cause
`netplan apply` returns before the network service has finished rebuilding the
routes. The script's `grep` ran inside that gap, found no route, and returned 1.
With `set -e` and `pipefail` at the top of the script, a non-zero return stops
the script, so Vagrant saw a failure. The route itself was never actually
missing for more than a moment. This is a race between `netplan apply` and the
check that follows it.

## Fix
In `provision/app.sh`, replaced the single `ip route | grep` check with a loop
that checks `ip route show 10.42.20.0/24` once a second for up to 10 seconds,
exits 0 as soon as the route appears, and exits 1 with a clear message if it
never does. Also `chmod 600 /etc/netplan/*.yaml` to silence netplan permission
warnings that were cluttering the output.

## Verified
Ran `vagrant provision` twice. Both runs printed
`app: route to 10.42.20.0/24 present` and continued on to backup, which printed
`10.42.10.0/24 via 10.42.20.1 dev enp0s8 proto static metric 101`.

## Follow-up
Any check in a provisioning script that runs right after a command that applies
config (netplan apply, nmcli connection up, systemctl restart) should wait and
retry rather than check once.