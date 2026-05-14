package yubikey-manager
write -a /etc/gnupg/scdaemon.conf disable-ccid
run systemctl enable pcscd.service

package evtest
copy -x res/bin/yubikey-lock.sh /usr/local/libexec/yubikey/lock
copy -x res/bin/yubikey-unlock.sh /usr/local/libexec/yubikey/unlock
copy res/udev/yubikey.rules /etc/udev/rules.d/yubikey.rules

package pam-u2f
copy -su u2f_keys .config/Yubico/u2f_keys
run sed -i '3a auth       sufficient                  pam_u2f.so           cue origin=pam://pascal' /etc/pam.d/system-auth
