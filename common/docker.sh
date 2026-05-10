package docker docker-compose docker-buildx
run usermod -aG docker pascal

persist /var/lib/docker
copy res/docker.json /etc/docker/daemon.json
write /etc/sysctl.d/docker.conf "net.ipv4.ip_forward = 1"

if [[ $HOST_KIND == desktop ]]; then
  run systemctl enable docker.socket
  copy res/systemd/system/docker.service /etc/systemd/system/docker.service.d/override.conf
fi
