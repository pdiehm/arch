package networkmanager nm-connection-editor
systemd -e NetworkManager.service

env NAME hotspot
env PRIORITY 25
env SSID "$(secret network/hotspot/ssid)"
env PSK "$(secret network/hotspot/psk)"
copy -em 400 res/NetworkManager/wifi-dhcp.nmconnection /etc/NetworkManager/system-connections/hotspot.nmconnection

env NAME eduroam
env PRIORITY 50
env SSID eduroam
env IDENTITY "$(secret network/eduroam/identity)"
env PASSWORD "$(secret network/eduroam/password)"
copy -s network/eduroam/private-key /etc/NetworkManager/system-connections/eduroam/private-key
copy -s network/eduroam/client-cert /etc/NetworkManager/system-connections/eduroam/client-cert
copy -s network/eduroam/ca-cert /etc/NetworkManager/system-connections/eduroam/ca-cert
copy -em 400 res/NetworkManager/wifi-eap.nmconnection /etc/NetworkManager/system-connections/eduroam.nmconnection
