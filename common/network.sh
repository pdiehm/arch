write /etc/hostname "$HOST_NAME"

copy res/systemd/resolved.conf /etc/systemd/resolved.conf
copy res/systemd/resolvconf.service /etc/systemd/system/resolvconf.service
run systemctl enable systemd-resolved.service resolvconf.service
