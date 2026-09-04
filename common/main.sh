import ./base
import ./pacman
import ./boot
import ./user
import ./locale
import ./network
import ./backup
import ./docker
import ./programs

write /etc/modules-load.d/zram.conf "zram"
copy res/udev/zram.rules /etc/udev/rules.d/99-zram.rules
write -a /etc/fstab "/dev/zram0 none swap x-systemd.makefs 0 0"

package openssh
copy res/ssh/sshd_config /etc/ssh/sshd_config
copy res/ssh/known_hosts /etc/ssh/ssh_known_hosts
copy -s "ssh/$HOST_NAME/host" /etc/ssh/host_key
copy -sm 444 "ssh/$HOST_NAME/auth" /etc/ssh/authorized_keys
systemd -m sshdgenkeys.service
systemd -e sshd.service
TCP+=(1970)

package fwupd
persist /var/lib/fwupd
persist /var/cache/fwupd
systemd -e fwupd-refresh.timer

systemd -e fstrim.timer
systemd -d systemd-userdbd.socket
persist /var/lib/systemd
persist -u .local/share/systemd

package pkgstats wireguard-tools \
  bat eza fd ripgrep jq pv fzf rsync parallel lsof \
  fastfetch usbutils pciutils dmidecode duf ncdu \
  curl xh openbsd-netcat doggo mtr tcpdump \
  btrfs-progs e2fsprogs exfatprogs dosfstools \
  libarchive zip unzip
