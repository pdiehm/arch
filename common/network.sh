package -c dynhostmgr
systemd dynhostmgr.service
write /etc/hostname "$HOST_NAME"

write /etc/hosts << EOF
127.0.0.1            localhost
::1                  localhost
192.168.1.89         homeassistant
91.99.52.233         goomba
2a01:4f8:c0c:988b::1 goomba
EOF

write /etc/dynhosts << EOF
arch   192.168.1.90
bowser 192.168.1.88
EOF

copy res/nftables.conf /etc/nftables.conf
systemd nftables.service

copy res/systemd/resolved.conf /etc/systemd/resolved.conf
copy res/systemd/system/resolvconf.service /etc/systemd/system/resolvconf.service
systemd systemd-resolved.service resolvconf.service
