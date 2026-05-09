import ./desktop
import ./gnupg
import ./nvim
import ./yubikey

symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/arch .ssh/arch
copy -nsu ssh/github .ssh/github

package git-delta
symlink -u res/git.conf .config/git/config

package pipewire pipewire-alsa wireplumber alsa-utils wiremix
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
