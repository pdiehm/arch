dropin hyprland.lua 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })'

env NAME home-wifi
env PRIORITY 50
env SSID "$(secret network/home-wifi/ssid)"
env PSK "$(secret network/home-wifi/psk)"
env ADDRESS 192.168.1.91/16
env GATEWAY 192.168.1.1
copy -em 400 res/NetworkManager/wifi-static.nmconnection /etc/NetworkManager/system-connections/home-wifi.nmconnection
