option cpu amd
run systemctl enable systemd-networkd.service

write /etc/systemd/network/wired.network << EOF
[Match]
Type=ether
Kind=!*

[Network]
DHCP=ipv4
EOF
