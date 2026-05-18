import ./hypr
import ./network
import ./gnupg
import ./ssh
import ./dev
import ./nvim
import ./yubikey

copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package android-file-transfer sshfs
symlink -u res/bin/mnt.sh .local/bin/mnt

package ffmpeg wiremix wl-clipboard
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
