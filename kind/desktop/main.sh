import ./dev
import ./gnupg
import ./hypr
import ./network
import ./nvim
import ./ssh
import ./yubikey

copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

package git git-delta
symlink -u res/git.conf .config/git/config

persist -u /home/pascal/Repos
symlink -u res/bin/repo.sh .local/bin/repo
timer -nu repo-fetch hourly "%h/.local/bin/repo" fetch

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package wl-clipboard
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
