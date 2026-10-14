#!/usr/bin/env bash
set -euo pipefail

echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-forward.conf
sysctl --system > /dev/null
echo "router: ip_forward=$(sysctl -n net.ipv4.ip_forward)"