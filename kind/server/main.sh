run sed -Ei "s/^pascal .*$/pascal ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers
systemd -e systemd-networkd.service
