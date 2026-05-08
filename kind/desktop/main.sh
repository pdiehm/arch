import ./desktop
import ./dev
import ./nvim
import ./yubikey

package pipewire pipewire-alsa wireplumber alsa-utils wiremix
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"
