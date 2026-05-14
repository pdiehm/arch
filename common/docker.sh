package docker docker-compose docker-buildx
copy res/docker.json /etc/docker/daemon.json
write /etc/sysctl.d/docker.conf "net.ipv4.ip_forward = 1"

persist /var/lib/docker
run usermod --append --groups docker pascal
timer docker-gc monthly /usr/bin/docker system prune --all --force --volumes

if [[ $HOST_KIND == desktop ]]; then
  copy res/systemd/system/docker.conf /etc/systemd/system/docker.service.d/override.conf
  systemd docker.socket
fi
