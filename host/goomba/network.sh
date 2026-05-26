write /etc/systemd/network/main.network << EOF
[Match]
Kind=!*
Type=ether

[Network]
DHCP=ipv4
Address=2a01:4f8:c0c:988b::1/64
Gateway=fe80::1
EOF

write -m 400 -o systemd-network /etc/systemd/network/wg-main.netdev << EOF
[NetDev]
Name=wg-main
Kind=wireguard

[WireGuard]
PrivateKey=$(secret wg/goomba)
ListenPort=51820
RouteTable=main

[WireGuardPeer]
PublicKey=$(secret wg/pub/bowser)
PresharedKey=$(secret wg/psk/main)
AllowedIPs=fd42:6c77:9a2f::2/128

[WireGuardPeer]
PublicKey=$(secret wg/pub/pascal-pc)
PresharedKey=$(secret wg/psk/main)
AllowedIPs=fd42:6c77:9a2f::1001/128

[WireGuardPeer]
PublicKey=$(secret wg/pub/pascal-laptop)
PresharedKey=$(secret wg/psk/main)
AllowedIPs=fd42:6c77:9a2f::1002/128
EOF

write /etc/systemd/network/wg-main.network << EOF
[Match]
Name=wg-main

[Network]
Address=fd42:6c77:9a2f::1/112
EOF

UDP+=(51820)
