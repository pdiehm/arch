package networkmanager nm-connection-editor
systemd -e NetworkManager.service

write -m 400 /etc/NetworkManager/system-connections/hotspot.nmconnection << EOF
[connection]
id=hotspot
type=wifi
autoconnect-priority=25

[wifi]
mode=infrastructure
ssid=$(secret net/hotspot/ssid)

[wifi-security]
key-mgmt=wpa-psk
psk=$(secret net/hotspot/psk)
EOF

write -m 400 /etc/NetworkManager/system-connections/eduroam.nmconnection << EOF
[connection]
id=eduroam
type=wifi
autoconnect-priority=50

[wifi]
mode=infrastructure
ssid=eduroam

[wifi-security]
key-mgmt=wpa-eap

[802-1x]
eap=tls
identity=$(secret net/eduroam/identity)
private-key-password=$(secret net/eduroam/password)
private-key=/etc/NetworkManager/system-connections/eduroam/private-key
client-cert=/etc/NetworkManager/system-connections/eduroam/client-cert
ca-cert=/etc/NetworkManager/system-connections/eduroam/ca-cert
EOF

copy -s net/eduroam/private-key /etc/NetworkManager/system-connections/eduroam/private-key
copy -s net/eduroam/client-cert /etc/NetworkManager/system-connections/eduroam/client-cert
copy -s net/eduroam/ca-cert /etc/NetworkManager/system-connections/eduroam/ca-cert
