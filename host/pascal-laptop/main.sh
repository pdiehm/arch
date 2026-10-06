import ./network

package tlp
systemd -e tlp.service
systemd -m systemd-rfkill.{service,socket}

write -au .config/dropin/hyprland.lua 'hl.monitor({ output = "eDP-1", scale = 1.33 })'
