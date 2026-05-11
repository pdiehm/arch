package yubikey-manager pam-u2f evtest
write -a /etc/gnupg/scdaemon.conf disable-ccid
run systemctl enable pcscd.service

copy -x res/scripts/yubikey-lock.sh /usr/local/libexec/yubikey-lock
copy -x res/scripts/yubikey-unlock.sh /usr/local/libexec/yubikey-unlock
copy res/udev/yubikey.rules /etc/udev/rules.d/yubikey.rules

copy -su u2f_keys .config/Yubico/u2f_keys
run sed -i '3a auth       sufficient                  pam_u2f.so           cue origin=pam://pascal' /etc/pam.d/system-auth
