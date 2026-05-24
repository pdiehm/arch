env ADDRESS "2a01:4f8:c0c:988b::1/64"
env GATEWAY "fe80::1"
copy -e res/systemd/network/ethernet-dhcp4.network /etc/systemd/network/main.network
