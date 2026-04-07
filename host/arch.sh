option cpu amd
package man-db man-pages

persist -u -m 700 .local/share/gnupg
symlink -u res/git.conf .config/git/config

package zsh zsh-autosuggestions zsh-completions zsh-syntax-highlighting
run chsh -s /usr/bin/zsh pascal
write /etc/zsh/zshenv "ZDOTDIR=\"\$HOME/.config/zsh\""
symlink -u res/zsh .config/zsh

package vim
write -a /etc/environment "EDITOR=vim"
copy res/vimrc.vim /etc/vimrc

package openssh
copy res/ssh/known_hosts /etc/ssh/ssh_known_hosts
symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/github/key .ssh/github

package ttf-noto-nerd ttf-firacode-nerd
symlink -u res/fontconfig.xml .config/fontconfig/fonts.conf

package hyprland kitty hyprpolkitagent hyprpaper mako rofi dolphin pipewire wireplumber xdg-desktop-portal-hyprland waybar wl-clipboard
symlink -u res/hypr .config/hypr

package neovim vim-spell-de tree-sitter-cli ripgrep fd
package lua-language-server bash-language-server
package stylua shfmt
symlink -u res/nvim .config/nvim

script -u << "EOF"
nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
EOF

package greetd-tuigreet
run systemctl enable greetd.service

write /etc/greetd/config.toml << "EOF"
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd 'sh -c \"exec $SHELL\"'"

[initial_session]
command = "systemd-cat --identifier Hyprland start-hyprland"
user = "pascal"
EOF

run systemctl enable systemd-networkd.service systemd-resolved.service
write /etc/systemd/network/wired.network << EOF
[Match]
Type=ether
Kind=!*

[Network]
DHCP=ipv4
EOF
