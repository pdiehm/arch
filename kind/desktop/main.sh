import ./gnupg
import ./hypr
import ./nvim
import ./ssh
import ./yubikey

package git-delta
symlink -u res/git.conf .config/git/config

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package pipewire pipewire-alsa wireplumber alsa-utils wiremix
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
