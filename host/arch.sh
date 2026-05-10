write /etc/systemd/network/wired.network << EOF
[Match]
Type=ether
Kind=!*

[Network]
DHCP=ipv4
EOF

run systemctl enable systemd-networkd.service
