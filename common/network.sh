write /etc/hostname "$HOST_NAME"

copy res/systemd/resolved.conf /etc/systemd/resolved.conf
copy res/systemd/resolvconf.service /etc/systemd/system/resolvconf.service
run systemctl enable systemd-resolved.service resolvconf.service

write -a /etc/hosts << EOF
192.168.1.88         bowser
91.99.52.233         goomba
2a01:4f8:c0c:988b::1 goomba
EOF
