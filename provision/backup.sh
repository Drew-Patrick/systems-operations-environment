#!/usr/bin/env bash
set -euo pipefail

CON=$(nmcli -g GENERAL.CONNECTION device show enp0s8)
nmcli connection modify "$CON" ipv4.routes "10.42.10.0/24 10.42.20.1"
nmcli connection up "$CON" > /dev/null
echo "backup: routes:"; ip route | grep 10.42.10