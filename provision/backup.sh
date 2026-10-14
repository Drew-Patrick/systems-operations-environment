#!/usr/bin/env bash
set -euo pipefail

# --- route back to net10 (Lesson 4/5) ---
CON=$(nmcli -g GENERAL.CONNECTION device show enp0s8)
nmcli connection modify "$CON" ipv4.routes "10.42.10.0/24 10.42.20.1"
nmcli connection up "$CON" > /dev/null
echo "backup: route:"; ip route | grep 10.42.10

# --- SSH on 2222 as well as 22 (Lesson 7) ---
# 1. sshd config
cat > /etc/ssh/sshd_config.d/10-lab-port.conf <<'EOF'
Port 22
Port 2222
EOF

# 2. SELinux: label 2222 as an SSH port (skip if already labeled)
dnf install -y -q policycoreutils-python-utils
if ! semanage port -l | grep '^ssh_port_t' | grep -qw 2222; then
  semanage port -a -t ssh_port_t -p tcp 2222
fi

# 3. firewalld: open 2222 (add-port is safe to repeat)
firewall-cmd --permanent --add-port=2222/tcp > /dev/null
firewall-cmd --reload > /dev/null

# 4. test config, then restart
sshd -t
systemctl restart sshd
echo "backup: sshd listening on:"; ss -tlnp | grep sshd | grep -o ':[0-9]* ' | sort -u

# --- receive backups from app (Lesson 8) ---
dnf install -y -q rsync
install -d -o vagrant -g vagrant /srv/backup
install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
touch /home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys; chmod 600 /home/vagrant/.ssh/authorized_keys
if [ -f /vagrant/provision/keys/app.pub ]; then
  grep -qF "$(cat /vagrant/provision/keys/app.pub)" /home/vagrant/.ssh/authorized_keys \
    || cat /vagrant/provision/keys/app.pub >> /home/vagrant/.ssh/authorized_keys
  echo "backup: app key installed"
else
  echo "backup: no app.pub found; provision app first" >&2
fi