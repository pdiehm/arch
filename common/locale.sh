symlink /usr/share/zoneinfo/Europe/Berlin /etc/localtime
run hwclock --systohc
systemd -e systemd-timesyncd.service

copy res/locale/locale.gen /etc/locale.gen
copy res/locale/locale.conf /etc/locale.conf
run locale-gen

write -a /etc/vconsole.conf "KEYMAP=de"
run mkinitcpio --allpresets
