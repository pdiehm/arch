import ./network
import ./hypr
import ./applications
import ./yubikey
import ./gnupg
import ./ssh
import ./dev
import ./nvim
import ./scripts

copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

package aerc w3m
symlink -u res/aerc .config/aerc
copy -su mail/gmail .local/keys/aerc/gmail
copy -su mail/uni .local/keys/aerc/uni

package ffmpeg wl-clipboard
script -u <<< "mkdir Downloads"
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
