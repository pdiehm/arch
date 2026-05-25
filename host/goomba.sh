write /etc/systemd/network/main.network << EOF
[Match]
Kind=!*
Type=ether

[Network]
DHCP=ipv4
Address=2a01:4f8:c0c:988b::1/64
Gateway=fe80::1
EOF
