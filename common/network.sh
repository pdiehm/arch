write /etc/hostname "$HOST_NAME"

write /etc/hosts << EOF
127.0.0.1            localhost
::1                  localhost
192.168.1.88         bowser
192.168.1.89         homeassistant
192.168.1.90         arch
91.99.52.233         goomba
2a01:4f8:c0c:988b::1 goomba
EOF

copy res/nftables.conf /etc/nftables.conf
systemd -e nftables.service

copy res/systemd/resolved.conf /etc/systemd/resolved.conf
systemd -i resolvconf.service
systemd -e systemd-resolved.service resolvconf.service
