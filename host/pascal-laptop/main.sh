import ./network
write -au .config/dropin/hyprland.lua 'hl.monitor({ output = "eDP-1", scale = 1.33 })'

package tlp
systemd -m systemd-rfkill.service systemd-rfkill.socket
systemd -e tlp.service
