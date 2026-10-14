# U01: router did not respond to SSH after vagrant reload

**Date:** 2026-10-13 (UTC)
**Machine(s):** router
**Severity:** low (lab only, no other machine affected)

## Symptom
`vagrant reload` ended with "Timed out while waiting for the machine to boot"
while connecting to router at 127.0.0.1:2222. Expected: router reboots and
Vagrant reconnects.

## Checked
- VirtualBox console for router: showed `router login:` prompt, so the VM had booted.
- `vagrant ssh router` by hand: logged in normally.

## Cause
Boot took longer than Vagrant's default boot_timeout (300 s). The VM was healthy;
only the wait was too short.

## Fix
None needed. The retry succeeded.

## Verified
`vagrant ssh router` logged in. Login banner showed eth0 at 10.0.2.15.

## Follow-up
If it recurs, raise `config.vm.boot_timeout` in the Vagrantfile.