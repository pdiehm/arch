package neovim wl-clipboard vim-spell-de tree-sitter-cli prettier \
  vscode-css-languageserver vscode-json-languageserver \
  bash-language-server shellcheck shfmt \
  lua-language-server stylua

package -a prettier-plugin-xml
package -c prettier-plugin-css-order

symlink -u res/nvim .config/nvim
write -au .config/dropin/env "EDITOR=nvim"

script -u << EOF
echo "Installing nvim treesitter parsers..."
nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
EOF

upgrade << EOF
echo "Upgrading nvim treesitter parsers..."
sudo -u pascal nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
sudo -u pascal nvim -es --cmd "lua require('nvim-treesitter').update():wait(60000)" --cmd q
EOF
