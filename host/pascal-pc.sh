env ADDRESS 192.168.1.90/16
env GATEWAY 192.168.1.1
copy -em 400 res/NetworkManager/wired.nmconnection /etc/NetworkManager/system-connections/wired.nmconnection
