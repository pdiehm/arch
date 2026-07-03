import ./boot
import ./locale
import ./network
import ./docker
import ./bwrap

write -a /etc/environment << EOF
HOSTNAME="$HOST_NAME"
HOSTKIND="$HOST_KIND"
EOF

package zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting
write -a /etc/zsh/zshenv 'ZDOTDIR="$HOME/.config/zsh"'
run chsh --shell /usr/bin/zsh pascal
symlink -u res/zsh .config/zsh

package vim
copy res/vimrc.vim /etc/vimrc
write -a /etc/environment "EDITOR=vim"

package git git-delta
symlink -u res/git.conf .config/git/config

package htop
copy -um 444 res/htop.conf .config/htop/htoprc

package openssh
copy res/ssh/sshd_config /etc/ssh/sshd_config
copy res/ssh/known_hosts /etc/ssh/ssh_known_hosts
copy -s "ssh/$HOST_NAME/host" /etc/ssh/host_key
copy -sm 444 "ssh/$HOST_NAME/auth" /etc/ssh/authorized_keys
systemd -m sshdgenkeys.service
systemd -e sshd.service
TCP+=(1970)

package tmux
symlink -u res/tmux.conf .config/tmux/tmux.conf

copy -x res/bin/ntfy.sh /usr/local/bin/ntfy
copy -sm 444 ntfy /usr/local/share/ntfy/token

systemd -e fstrim.timer

package man-db man-pages pkgstats wireguard-tools \
  bat eza fd ripgrep jq pv fzf rsync parallel \
  lsof usbutils pciutils fastfetch duf ncdu \
  curl xh openbsd-netcat doggo mtr tcpdump \
  btrfs-progs e2fsprogs exfatprogs dosfstools \
  libarchive zip unzip
