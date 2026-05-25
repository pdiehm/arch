write -m 400 /etc/NetworkManager/system-connections/home-wifi.nmconnection << EOF
[connection]
id=home-wifi
type=wifi
autoconnect-priority=50

[wifi]
mode=infrastructure
ssid=$(secret net/home-wifi/ssid)

[wifi-security]
key-mgmt=wpa-psk
psk=$(secret net/home-wifi/psk)

[ipv4]
method=manual
addresses=192.168.1.91/16
gateway=192.168.1.1
EOF

package tlp
systemd -m systemd-rfkill.service systemd-rfkill.socket
systemd -e tlp.service

dropin hyprland.lua 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })'
