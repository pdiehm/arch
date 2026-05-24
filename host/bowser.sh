env ADDRESS 192.168.1.88/16
env GATEWAY 192.168.1.1
copy -e res/systemd/network/ethernet.network /etc/systemd/network/main.network
