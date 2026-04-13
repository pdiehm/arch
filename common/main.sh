import ./boot
import ./locale
import ./network

package zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting
run chsh -s /usr/bin/zsh pascal
write /etc/zsh/zshenv "ZDOTDIR=\"\$HOME/.config/zsh\""
symlink -u res/zsh .config/zsh

package vim
write -a /etc/environment "EDITOR=vim"
copy res/vimrc.vim /etc/vimrc

package openssh
copy res/ssh/known_hosts /etc/ssh/ssh_known_hosts

package man-db man-pages bat eza fd ripgrep fzf pv duf ncdu
