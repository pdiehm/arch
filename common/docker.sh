package docker docker-compose docker-buildx
persist /var/lib/docker
persist /var/lib/containerd
copy res/docker.json /etc/docker/daemon.json
run usermod --append --groups docker pascal
timer docker-gc monthly /usr/bin/docker system prune --all --force --volumes

if [[ $HOST_KIND == desktop ]]; then
  systemd -o docker.service
  systemd -e docker.socket
elif [[ $HOST_KIND == server ]]; then
  persist -u docker
  systemd -e docker.service
fi
