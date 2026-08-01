copy -x res/bin/journalwatch.sh /usr/local/lib/journalwatch/journalwatch.sh
systemd -i journalwatch.service
systemd -e journalwatch.service

copy -x bin/manager.sh /var/local/syscfg/bin/manager.sh
copy -x bin/lib.sh /var/local/syscfg/bin/lib.sh
timer -n auto-upgrade "Sun 03:00" /bin/sh -c "/var/local/syscfg/bin/manager.sh upgrade && reboot"

run sed -Ei "s/^pascal .*$/pascal ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers
systemd -e systemd-networkd.service
