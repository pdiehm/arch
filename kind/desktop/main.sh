import ./network
import ./hypr
import ./applications
import ./gnupg
import ./ssh
import ./dev
import ./nvim
import ./yubikey

copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

package aerc w3m
symlink -u res/aerc .config/aerc
copy -su mail/gmail .local/keys/aerc/gmail
copy -su mail/uni .local/keys/aerc/uni

package android-file-transfer sshfs
symlink -u res/bin/mnt.sh .local/bin/mnt

package ffmpeg wl-clipboard
script -u <<< "mkdir Downloads"
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
