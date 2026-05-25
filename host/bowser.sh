write /etc/systemd/network/main.network << EOF
[Match]
Kind=!*
Type=ether

[Network]
Address=192.168.1.88/16
Gateway=192.168.1.1
EOF

persist -u shared
