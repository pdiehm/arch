import ./boot
import ./bwrap
import ./docker
import ./locale
import ./network

write -a /etc/environment << EOF
HOSTNAME="$HOST_NAME"
HOSTKIND="$HOST_KIND"
EOF

package paru base-devel devtools nvchecker
conf -e /etc/paru.conf BottomUp CleanAfter RemoveMake SudoLoop

package zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting
write -a /etc/zsh/zshenv "ZDOTDIR=\"\$HOME/.config/zsh\""
run chsh --shell /usr/bin/zsh pascal
symlink -u res/zsh .config/zsh

package vim
write -a /etc/environment "EDITOR=vim"
copy res/vimrc.vim /etc/vimrc

package htop
symlink -u res/htop.conf .config/htop/htoprc

package openssh
copy res/ssh/sshd_config /etc/ssh/sshd_config
copy res/ssh/known_hosts /etc/ssh/ssh_known_hosts
copy -s "ssh/$HOST_NAME/host" /etc/ssh/host_key
copy -sm 444 "ssh/$HOST_NAME/auth" /etc/ssh/authorized_keys
systemd -m sshdgenkeys.service
systemd -e sshd.service

package man-db man-pages zip unzip \
  bat eza fd ripgrep pv fzf parallel \
  lsof usbutils pciutils fastfetch duf ncdu \
  openbsd-netcat doggo mtr xh tcpdump \
  btrfs-progs e2fsprogs exfatprogs dosfstools
