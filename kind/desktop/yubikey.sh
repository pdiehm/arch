package yubikey-manager
write -a /etc/gnupg/scdaemon.conf "disable-ccid"
systemd -e pcscd.service

package pam-u2f
copy -su u2f_keys .config/Yubico/u2f_keys
run sed -i "3a auth sufficient pam_u2f.so cue origin=pam://pascal" /etc/pam.d/system-auth

package evtest
copy -x res/bin/yubikey-lock.sh /usr/local/lib/yubikey/lock
copy -x res/bin/yubikey-unlock.sh /usr/local/lib/yubikey/unlock
copy res/udev/yubikey.rules /etc/udev/rules.d/yubikey.rules
