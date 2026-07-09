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

package tlrc
persist -u .cache/tlrc
timer -nu tldr-update daily /usr/bin/tldr --update

write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"
copy res/systemd/logind.conf /etc/systemd/logind.conf
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs uid=1000,gid=1000 0 0"

package reflector hexedit nmap yt-dlp perl-image-exiftool vhs \
  ffmpeg mpv mpv-mpris imagemagick gimp inkscape poppler pdfpc \
  wev wl-clipboard wf-recorder wl-mirror
