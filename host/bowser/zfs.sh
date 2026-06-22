package zfs-linux-lts
run sed -i 's/Priority: high/Priority: default/' /etc/zfs/zed.d/zed-functions.sh
systemd -e zfs.target zfs-import.target zfs-import-scan.service zfs-mount.service zfs-zed.service
timer zfs-scrub-all weekly /usr/bin/zpool scrub -a

write /etc/zfs/zed.d/zed.rc << EOF
ZED_NOTIFY_VERBOSE=1
ZED_NTFY_URL="https://ntfy.pdiehm.dev"
ZED_NTFY_TOPIC="bowser"
ZED_NTFY_ACCESS_TOKEN="$(secret ntfy)"
EOF
