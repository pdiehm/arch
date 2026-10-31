package xdg-utils xdg-user-dirs archlinux-xdg-menu adwaita-icon-theme
copy res/user-dirs.defaults /etc/xdg/user-dirs.defaults
symlink -u res/mimeapps.list .config/mimeapps.list

package pipewire pipewire-{alsa,pulse} wireplumber wiremix alsa-utils rtkit
persist -u .local/state/wireplumber

package networkmanager nm-connection-editor network-manager-applet dnsmasq
systemd -e NetworkManager.service

package bluez bluez-utils
persist /var/lib/bluetooth
systemd -e bluetooth.service
conf /etc/bluetooth/main.conf "AutoEnable=false"
