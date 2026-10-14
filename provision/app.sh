#!/usr/bin/env bash
set -euo pipefail

# --- route to net20 (Lesson 4/5) ---
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

ok=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  if [[ "$(ip route show 10.42.20.0/24)" == *via* ]]; then
    ok=1
    break
  fi
  sleep 1
done
if [ "$ok" = 1 ]; then
  echo "app: route to 10.42.20.0/24 present"
else
  echo "app: route to 10.42.20.0/24 missing after netplan apply" >&2
  exit 1
fi

# --- SSH key and shortcut for the vagrant user (Lesson 6/8) ---
H=/home/vagrant
install -d -m 700 -o vagrant -g vagrant "$H/.ssh"
if [ ! -f "$H/.ssh/id_ed25519" ]; then
  sudo -u vagrant ssh-keygen -t ed25519 -N "" -f "$H/.ssh/id_ed25519" -q
fi
cat > "$H/.ssh/config" <<'EOF'
Host backup
    HostName 10.42.20.10
    Port 2222
    User vagrant
    StrictHostKeyChecking accept-new
EOF
chown vagrant:vagrant "$H/.ssh/config"; chmod 600 "$H/.ssh/config"
# hand the public key to backup's provisioner via the shared folder
install -d /vagrant/provision/keys
cp "$H/.ssh/id_ed25519.pub" /vagrant/provision/keys/app.pub

# --- data folder (Lesson 8) ---
install -d -o vagrant -g vagrant /srv/data

# --- scheduled backup (Lesson 9) ---
install -m 644 /vagrant/provision/app/backup.service /vagrant/provision/app/backup.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now backup.timer
echo "app: backup timer:"; systemctl list-timers backup.timer --no-pager | sed -n 2p