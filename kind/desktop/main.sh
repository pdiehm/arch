import ./dev
import ./gnupg
import ./hypr
import ./network
import ./nvim
import ./ssh
import ./yubikey

copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package wl-clipboard
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
