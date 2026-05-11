import ./gnupg
import ./hypr
import ./nvim
import ./ssh
import ./yubikey

write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
persist -u /home/pascal/Repos

symlink -u res/systemd/user .config/systemd/user
persist -u .local/share/systemd

package networkmanager nm-connection-editor
run systemctl enable NetworkManager.service

package git-delta
symlink -u res/git.conf .config/git/config

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json
