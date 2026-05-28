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

write -m 400 /etc/NetworkManager/system-connections/wg-main.nmconnection << EOF
[connection]
id=@main
type=wireguard
interface-name=wg-main

[ipv6]
method=manual
addresses=fd42:6c77:9a2f::1002/112
addr-gen-mode=stable-privacy

[wireguard]
private-key=$(secret wg/pascal-laptop)
private-key-flags=0

[wireguard-peer.$(secret wg/pub/goomba)]
preshared-key=$(secret wg/psk/main)
preshared-key-flags=0
allowed-ips=fd42:6c77:9a2f::/112
endpoint=goomba:51820
persistent-keepalive=10
EOF
