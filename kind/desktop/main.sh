import ./gnupg
import ./hypr
import ./nvim
import ./ssh
import ./yubikey

package git-delta
symlink -u res/git.conf .config/git/config

package pipewire pipewire-alsa wireplumber alsa-utils wiremix
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
