package docker docker-compose docker-buildx
copy res/docker.json /etc/docker/daemon.json
write /etc/sysctl.d/docker.conf "net.ipv4.ip_forward = 1"

persist /var/lib/docker
run usermod --append --groups docker pascal

if [[ $HOST_KIND == desktop ]]; then
  copy res/systemd/system/docker.conf /etc/systemd/system/docker.service.d/override.conf
  run systemctl enable docker.socket
fi
