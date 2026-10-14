# 003: app cannot reach backup after route to 10.42.20.0/24 removed

**Date:** 2026-10-14 (UTC)
**Machine(s):** app
**Severity:**  (one host cannot reach a whole subnet)

## Symptom
From app, `ping -c 3 10.42.20.10` printed no replies and ended with
`3 packets transmitted, 0 received, 100% packet loss`. No error message, just silence.
Expected: replies with `ttl=63`, as on previous runs.
Cause of the break (planned): `sudo ip route del 10.42.20.0/24` on app.

## Checked
- On app: `ip route`. The line `10.42.20.0/24 via 10.42.10.1 dev eth1 proto static`
  was gone. The only line that could match 10.42.20.10 was
  `default via 10.0.2.2 dev eth0`.
- On app: `ip route get 10.42.20.10` printed
  `10.42.20.10 via 10.0.2.2 dev eth0 src 10.0.2.15`. The packet was being handed to the
  VirtualBox NAT gateway out eth0, not to the lab router out eth1.
- On app: `tracepath -n 10.42.20.10`. Hop 1 was 10.0.2.2, then `no reply` for every hop
  after. The packet reached the NAT gateway and died there.

## Cause
With the specific route gone, app fell back to its default route. The default gateway
(10.0.2.2, VirtualBox NAT) has no path to 10.42.20.0/24 and silently dropped the packets.
Silence rather than "Network is unreachable" because app did have a matching line
(default); the drop happened one hop downstream.

## Fix
On app: `sudo netplan apply`, which re-read the saved config in
`/etc/netplan/60-lab-routes.yaml` and restored the static route. No route was retyped
by hand.

## Verified
- On app: `ip route` showed `10.42.20.0/24 via 10.42.10.1 dev eth1 proto static` again.
- On app: `ping -c 2 10.42.20.10` returned replies with `ttl=63`.

## Follow-up
Silent packet loss to one subnet while other traffic works: run `ip route get <addr>`
first. If it names the wrong gateway or door, the fix is on this host's routing table.
Restore routes from saved config (`netplan apply`, `nmcli connection up`) rather than
retyping them, so the live and saved copies stay in step.

Side observation: `ip route` run immediately after `netplan apply` showed a table with
only one line and `ping` said `Network is unreachable`; a second later the full table was
back. `netplan apply` rebuilds the table asynchronously. Checks that run right after it
must wait (see U02).