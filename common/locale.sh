write /etc/locale.gen << EOF
de_DE.UTF-8 UTF-8
en_DK.UTF-8 UTF-8
en_US.UTF-8 UTF-8
EOF

write /etc/locale.conf << EOF
LANG=en_US.UTF-8
LC_ADDRESS=de_DE.UTF-8
LC_COLLATE=C.UTF-8
LC_MEASUREMENT=de_DE.UTF-8
LC_MONETARY=de_DE.UTF-8
LC_PAPER=de_DE.UTF-8
LC_TELEPHONE=de_DE.UTF-8
LC_TIME=en_DK.UTF-8
EOF

symlink /usr/share/zoneinfo/Europe/Berlin /etc/localtime
write /etc/vconsole.conf "KEYMAP=de"
run locale-gen
run hwclock --systohc
