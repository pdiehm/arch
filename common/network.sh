copy res/systemd/resolved.conf /etc/systemd/resolved.conf
systemd -i resolvconf.service
systemd -e systemd-resolved.service resolvconf.service

write /etc/hosts << EOF
127.0.0.1            localhost
::1                  localhost
192.168.1.89         homeassistant
91.99.52.233         goomba
2a01:4f8:c0c:988b::1 goomba
EOF

package dynhostmgr
systemd -e dynhostmgr.service

write /etc/dynhosts << EOF
bowser        192.168.1.88 fd42:6c77:9a2f::2
pascal-pc     192.168.1.90 fd42:6c77:9a2f::1001
pascal-laptop 192.168.1.91 fd42:6c77:9a2f::1002
EOF

if ((DRY)); then
  TCP=(1234)
  UDP=(1234)
else
  var TCP "$(IFS=, && echo "${TCP[*]}")"
  var UDP "$(IFS=, && echo "${UDP[*]}")"
  copy -v res/nftables.conf /etc/nftables.conf
  systemd -e nftables.service
fi

write /etc/sysctl.d/forwarding.conf << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
