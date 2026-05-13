import ./dev
import ./gnupg
import ./hypr
import ./network
import ./nvim
import ./ssh
import ./yubikey

persist -u .local/share/systemd
symlink -u res/systemd/user .config/systemd/user

package git-delta
symlink -u res/git.conf .config/git/config

persist -u /home/pascal/Repos
symlink -u res/bin/repo.sh .local/bin/repo

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
