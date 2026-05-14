package networkmanager nm-connection-editor
systemd NetworkManager.service

env NAME hotspot
env PRIORITY 25
env SSID "$(secret network/hotspot/ssid)"
env PSK "$(secret network/hotspot/psk)"
copy -em 400 res/NetworkManager/wifi-dhcp.nmconnection /etc/NetworkManager/system-connections/hotspot.nmconnection
