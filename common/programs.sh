package zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting
write -a /etc/zsh/zshenv 'ZDOTDIR="$HOME/.config/zsh"'
run chsh --shell /usr/bin/zsh pascal
symlink -u res/zsh .config/zsh

package vim
copy res/vimrc.vim /etc/vimrc
write -a /etc/environment "EDITOR=vim"

package git git-delta
symlink -u res/git.conf .config/git/config

package man-db man-pages
persist /var/cache/man

package htop
copy -um 444 res/htop.conf .config/htop/htoprc

package tmux
symlink -u res/tmux.conf .config/tmux/tmux.conf

copy -x res/bin/ntfy.sh /usr/local/bin/ntfy
copy -sm 444 ntfy /usr/local/lib/ntfy/token
