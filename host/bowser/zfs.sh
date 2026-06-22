package zfs-linux-lts
run sed -i 's/Priority: high/Priority: default/' /etc/zfs/zed.d/zed-functions.sh

write /etc/zfs/zed.d/zed.rc << EOF
ZED_NOTIFY_VERBOSE=1
ZED_NTFY_URL="https://ntfy.pdiehm.dev"
ZED_NTFY_TOPIC="bowser"
ZED_NTFY_ACCESS_TOKEN="$(secret ntfy)"
EOF
