copy -x res/bin/journalwatch.sh /usr/local/lib/journalwatch
systemd -i journalwatch.service
systemd -e journalwatch.service

run sed -Ei "s/^pascal .*$/pascal ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers
systemd -e systemd-networkd.service
