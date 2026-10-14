# 004: app cannot reach backup after its subnet mask changed from /24 to /16

**Date:** 2026-10-14 (UTC)
**Machine(s):** app
**Severity:** high (host unreachable to every other subnet while
appearing healthy)

## Symptom
From app, `ping -c 3 10.42.20.10` printed
`From 10.42.10.10 icmp_seq=1 Destination Host Unreachable` three times, then
`+3 errors, 100% packet loss`. The "From" address is app's own, so app itself was
reporting the failure.
At the same time `ping -c 3 10.42.10.1` (the router's door on app's subnet) worked
normally with `ttl=64`.
Expected: replies from 10.42.20.10 with `ttl=63`.
Cause of the break (planned): on app,
`sudo ip addr del 10.42.10.10/24 dev eth1` then `sudo ip addr add 10.42.10.10/16 dev eth1`.

## Checked
- On app: `ip a show eth1` showed `inet 10.42.10.10/16`. Mask should be /24.
- On app: `ip route`. The connected route was now `10.42.0.0/16 dev eth1 proto kernel`,
  covering all of 10.42.x.x as directly attached. The static route
  `10.42.20.0/24 via 10.42.10.1` was gone; the kernel removed it when the /24 address
  it depended on was deleted.
- On app: `ip route get 10.42.20.10` printed `10.42.20.10 dev eth1 src 10.42.10.10`.
  No `via`. App intended to deliver directly on its own link, not through the router.
- On app: `ip neigh` showed `10.42.10.1 dev eth1 lladdr 08:00:27:10:02:fc REACHABLE`
  (the router answered ARP) and `10.42.20.10 dev eth1 FAILED` (backup never answered
  ARP, because it is not on this link).

## Cause
With a /16 mask, app believed 10.42.20.10 was on its own subnet and tried to resolve it
by ARP on eth1 instead of sending it to the router. backup is on a different link
(net20), so no ARP reply ever came, and app reported "Destination Host Unreachable"
itself. The gateway still responded because it really is on app's link. A wrong mask
produces exactly this fingerprint: gateway reachable, everything beyond it "unreachable"
with the router never involved.

## Fix
On app: `sudo netplan apply`, which restored `10.42.10.10/24` from the saved config.
Restoring the /24 address also brought the static route back automatically.

## Verified
- On app: `ip a show eth1` showed `inet 10.42.10.10/24 brd 10.42.10.255`.
- On app: `ip route` showed `10.42.10.0/24 dev eth1` and
  `10.42.20.0/24 via 10.42.10.1 dev eth1 proto static`.
- On app: `ping -c 3 10.42.20.10` returned replies with `ttl=63`.

## Follow-up
"Destination Host Unreachable" reported from the host's own address means an ARP
failure: the host thinks the target is local. Check `ip neigh` for a FAILED entry,
then the mask in `ip a`. A host that can ping its gateway but nothing past it, with
`ip route get` showing no `via`, has a mask problem, not a network problem.