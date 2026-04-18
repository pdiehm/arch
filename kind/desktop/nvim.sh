package neovim vim-spell-de tree-sitter-cli prettier \
  bash-language-server shellcheck shfmt \
  lua-language-server stylua \
  vscode-css-languageserver \
  vscode-json-languageserver

package -c prettier-plugin-css-order

symlink -u res/nvim .config/nvim
write -au .config/dropin/env "EDITOR=nvim"

script -u << EOF
nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
EOF
