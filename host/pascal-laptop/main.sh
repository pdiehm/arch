import ./network

package tlp
systemd -m systemd-rfkill.service systemd-rfkill.socket
systemd -e tlp.service

dropin hyprland.lua 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })'
