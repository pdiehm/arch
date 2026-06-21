write /etc/systemd/network/main.network << EOF
[Match]
Kind=!*
Type=ether

[Network]
Address=192.168.1.88/16
Gateway=192.168.1.1
EOF

write -m 400 -o systemd-network /etc/systemd/network/wg.netdev << EOF
[NetDev]
Name=wg
Kind=wireguard

[WireGuard]
PrivateKey=$(secret wg/bowser)
RouteTable=main

[WireGuardPeer]
PublicKey=$(secret wg/pub/goomba)
PresharedKey=$(secret wg/psk/main)
AllowedIPs=fd42:6c77:9a2f::/112
Endpoint=goomba:51820
PersistentKeepalive=10
EOF

write /etc/systemd/network/wg.network << EOF
[Match]
Name=wg

[Network]
Address=fd42:6c77:9a2f::2/112
EOF
