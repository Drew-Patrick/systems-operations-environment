#!/usr/bin/env bash
set -euo pipefail

cat > /etc/netplan/60-lab-routes.yaml <<'EOF'
network:
  version: 2
  ethernets:
    eth1:
      routes:
        - to: 10.42.20.0/24
          via: 10.42.10.1
EOF
chmod 600 /etc/netplan/60-lab-routes.yaml
netplan apply
echo "app: routes:"; ip route | grep 10.42.20