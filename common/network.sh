copy res/systemd/resolved.conf /etc/systemd/resolved.conf
systemd -e systemd-resolved.service
systemd -ie resolvconf.service

package dynhostmgr
systemd -e dynhostmgr.service
copy res/hosts/static /etc/hosts
copy res/hosts/dynamic /etc/dynhosts

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
