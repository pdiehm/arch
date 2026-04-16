package yubikey-manager evtest
write -a /etc/gnupg/scdaemon.conf disable-ccid
run systemctl enable pcscd.service

copy res/bin/yubikey-lock /usr/local/bin/yubikey-lock
copy res/bin/yubikey-unlock /usr/local/bin/yubikey-unlock
copy res/udev/yubikey.rules /etc/udev/rules.d/yubikey.rules
