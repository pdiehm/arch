copy res/locale/locale.gen /etc/locale.gen
copy res/locale/locale.conf /etc/locale.conf
symlink /usr/share/zoneinfo/Europe/Berlin /etc/localtime
write -a /etc/vconsole.conf "KEYMAP=de"

run locale-gen
run hwclock --systohc
