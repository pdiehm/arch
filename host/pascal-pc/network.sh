write -m 400 /etc/NetworkManager/system-connections/wired.nmconnection << EOF
[connection]
id=wired
type=ethernet
autoconnect-priority=100

[ipv4]
method=manual
addresses=192.168.1.90/16
gateway=192.168.1.1
EOF

write -m 400 /etc/NetworkManager/system-connections/wg-main.nmconnection << EOF
[connection]
id=@main
type=wireguard
interface-name=wg-main

[ipv6]
method=manual
addresses=fd42:6c77:9a2f::1001/112
addr-gen-mode=stable-privacy

[wireguard]
private-key=$(secret wg/pascal-pc)
private-key-flags=0

[wireguard-peer.$(secret wg/pub/goomba)]
preshared-key=$(secret wg/psk/main)
preshared-key-flags=0
allowed-ips=fd42:6c77:9a2f::/112
endpoint=goomba:51820
persistent-keepalive=10
EOF
