package docker docker-compose docker-buildx
copy res/docker.json /etc/docker/daemon.json
run usermod --append --groups docker pascal

persist /var/lib/docker
persist /var/lib/containerd
timer docker-gc monthly /usr/bin/docker system prune --all --force --volumes

if [[ $HOST_KIND == desktop ]]; then
  systemd -e docker.socket
  write /etc/systemd/system/docker.service.d/prune.conf "[Service]" 'ExecStop=/bin/sh -c "docker container ls --all --quiet | xargs -r docker container rm --force"'
elif [[ $HOST_KIND == server ]]; then
  systemd -e docker.service
  persist -u docker

  BACKUP+=("/home/pascal/docker/**/.env" "/var/lib/docker/volumes/*/")
  write -ax /usr/local/lib/backup/pre.sh "systemctl stop docker.service"
  write -ax /usr/local/lib/backup/post.sh "systemctl start docker.service"
else
  error "Illegal host kind: $HOST_KIND"
fi
