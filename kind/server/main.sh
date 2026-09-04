copy -x res/bin/journalwatch.sh /usr/local/lib/journalwatch/journalwatch.sh
systemd -i journalwatch.service
systemd -e journalwatch.service

copy -x bin/manager.sh /usr/local/lib/syscfg/bin/manager.sh
copy -x bin/lib.sh /usr/local/lib/syscfg/bin/lib.sh
timer -n auto-upgrade "Sun 03:00" /bin/sh -c "/usr/local/lib/syscfg/bin/manager.sh upgrade && reboot"

systemd -e systemd-networkd.service
