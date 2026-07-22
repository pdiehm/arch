import ./network
write -au .config/dropin/hyprland.lua 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })'

package bluez bluez-utils
persist /var/lib/bluetooth
systemd -e bluetooth.service

package tlp
systemd -m systemd-rfkill.service systemd-rfkill.socket
systemd -e tlp.service
