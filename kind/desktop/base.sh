package pipewire pipewire-alsa pipewire-pulse wireplumber wiremix alsa-utils
persist -u .local/state/wireplumber

package networkmanager nm-connection-editor
systemd -e NetworkManager.service

package bluez bluez-utils
persist /var/lib/bluetooth
systemd -e bluetooth.service
conf /etc/bluetooth/main.conf "AutoEnable=false"
