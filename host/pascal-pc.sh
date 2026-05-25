write -m 400 /etc/NetworkManager/system-connections/wired.nmconnection << EOF
[connection]
id=wired
type=ethernet
autoconnect-priority=100

[ipv4]
method=manual
addresses=192.168.1.90/16
gateway=192.168.1.1
EOF
