package docker docker-compose docker-buildx
persist /var/lib/docker
persist /var/lib/containerd
copy res/docker.json /etc/docker/daemon.json
run usermod --append --groups docker pascal
timer docker-gc monthly /usr/bin/docker system prune --all --force --volumes

write /etc/sysctl.d/docker.conf << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOF

if [[ $HOST_KIND == desktop ]]; then
  systemd -o docker.service
  systemd -e docker.socket
fi
