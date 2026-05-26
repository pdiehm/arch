write /etc/hostname "$HOST_NAME"

write /etc/hosts << EOF
127.0.0.1            localhost
::1                  localhost
192.168.1.88         bowser
192.168.1.89         homeassistant
192.168.1.90         pascal-pc
192.168.1.91         pascal-laptop
91.99.52.233         goomba
2a01:4f8:c0c:988b::1 goomba
EOF

write /etc/sysctl.d/forwarding.conf << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

copy res/systemd/resolved.conf /etc/systemd/resolved.conf
systemd -i resolvconf.service
systemd -e systemd-resolved.service resolvconf.service

if [[ $PHASE == declare ]]; then
  TCP=(1234)
  UDP=(1234)
fi

env TCP "$(IFS=, && echo "${TCP[*]}")"
env UDP "$(IFS=, && echo "${UDP[*]}")"
copy -e res/nftables.conf /etc/nftables.conf
systemd -e nftables.service
