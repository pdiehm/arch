symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/github/key .ssh/github

persist -u -m 700 .local/share/gnupg
run ln -sf /usr/bin/pinentry-tty /usr/bin/pinentry

package git-delta
symlink -u res/git.conf .config/git/config

package neovim vim-spell-de tree-sitter-cli bash-language-server shellcheck lua-language-server shfmt stylua
symlink -u res/nvim .config/nvim

script -u << EOF
nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
EOF

write -au .config/dropin/env << "EOF"
export EDITOR="nvim"
export GNUPGHOME="$HOME/.local/share/gnupg"
export GPG_TTY="$(tty)"
EOF
