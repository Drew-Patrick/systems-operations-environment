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
chmod 600 /etc/netplan/*.yaml
netplan apply

for i in 1 2 3 4 5 6 7 8 9 10; do
  if ip route show 10.42.20.0/24 | grep -q via; then
    echo "app: route to 10.42.20.0/24 present"
    exit 0
  fi
  sleep 1
done
echo "app: route to 10.42.20.0/24 missing after netplan apply" >&2
exit 1