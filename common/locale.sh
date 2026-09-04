symlink /usr/share/zoneinfo/Europe/Berlin /etc/localtime
systemd -e systemd-timesyncd.service
run hwclock --systohc

copy res/locale/locale.gen /etc/locale.gen
copy res/locale/locale.conf /etc/locale.conf
run locale-gen
