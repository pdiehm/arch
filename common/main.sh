import ./boot
import ./docker
import ./locale
import ./network

write -a /etc/environment << EOF
HOSTNAME="$HOST_NAME"
HOSTKIND="$HOST_KIND"
EOF

package zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting
write -a /etc/zsh/zshenv "ZDOTDIR=\"\$HOME/.config/zsh\""
run chsh -s /usr/bin/zsh pascal
symlink -u res/zsh .config/zsh

package vim
write -a /etc/environment "EDITOR=vim"
copy res/vimrc.vim /etc/vimrc

package openssh
copy res/ssh/sshd_config /etc/ssh/sshd_config
copy res/ssh/known_hosts /etc/ssh/ssh_known_hosts
copy -ns "ssh/$HOST_NAME/host" /etc/ssh/host_key
copy -s -m 444 "ssh/$HOST_NAME/auth" /etc/ssh/authorized_keys
run systemctl mask sshdgenkeys.service
run systemctl enable sshd.service

copy res/systemd/system/gc.timer /etc/systemd/system/gc.timer
copy res/systemd/system/gc.service /etc/systemd/system/gc.service
run systemctl enable gc.timer

package \
  man-db man-pages \
  bat eza fd ripgrep pv fzf parallel \
  fastfetch duf ncdu \
  openbsd-netcat doggo mtr xh
