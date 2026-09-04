import ./base
import ./interface
import ./applications
import ./yubikey
import ./gnupg
import ./ssh
import ./dev
import ./nvim
import ./scripts

package tlrc
persist -u .cache/tlrc
timer -nu tldr-update daily /usr/bin/tldr --update

write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs uid=1000,gid=1000 0 0"
run -u mkdir Downloads

copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

package reflector hexedit nmap yt-dlp perl-image-exiftool vhs \
  mesa mesa-utils "vulkan-$HOST_GPU" vulkan-icd-loader vulkan-tools \
  ffmpeg mpv mpv-mpris imagemagick gimp inkscape poppler pdfpc \
  wev wl-clipboard wf-recorder wl-mirror
