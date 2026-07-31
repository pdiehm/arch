import ./hypr
import ./applications
import ./yubikey
import ./gnupg
import ./ssh
import ./dev
import ./nvim
import ./scripts

package networkmanager nm-connection-editor
systemd -e NetworkManager.service

package bluez bluez-utils
persist /var/lib/bluetooth
conf /etc/bluetooth/main.conf "AutoEnable=false"
systemd -e bluetooth.service

package tlrc
persist -u .cache/tlrc
timer -nu tldr-update hourly /usr/bin/tldr --update

package mesa mesa-utils "vulkan-$HOST_GPU" vulkan-icd-loader vulkan-tools
copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

run usermod --password "$(secret password)" pascal
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs uid=1000,gid=1000 0 0"
run -u mkdir Downloads

package reflector hexedit nmap yt-dlp perl-image-exiftool vhs \
  ffmpeg mpv mpv-mpris imagemagick gimp inkscape poppler pdfpc \
  wev wl-clipboard wf-recorder wl-mirror
