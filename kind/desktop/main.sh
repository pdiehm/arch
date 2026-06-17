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

copy res/systemd/logind.conf /etc/systemd/logind.conf
write /etc/sysctl.d/sysrq.conf "kernel.sysrq = 1"

script -u <<< "mkdir Downloads"
write -a /etc/fstab "tmpfs /home/pascal/Temp tmpfs defaults 0 0"

package dmidecode hexedit nmap perl-image-exiftool yt-dlp vhs \
  ffmpeg mpv mpv-mpris imagemagick gimp inkscape poppler pdfpc \
  wev wl-clipboard wf-recorder wl-mirror
