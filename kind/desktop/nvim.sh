package neovim vim-spell-de tree-sitter-cli
package clang rust-analyzer yaml-language-server

package bash-language-server shellcheck shfmt
package cmake-language-server cmake-format
package dockerfile-language-server dockerfmt
package java-language-server google-java-format
package lua-language-server stylua
package nixd nixfmt
package phpactor prettier-plugin-php
package python-lsp-server python-black python-isort
package texlab bibtex-tidy

package typescript-language-server eslint-language-server
package prettier prettier-plugin-css-order prettier-plugin-xml
package vscode-css-languageserver vscode-html-languageserver vscode-json-languageserver

symlink -u res/nvim .config/nvim
write -au .config/dropin/env.sh "EDITOR=nvim"

script -u << EOF
echo "Installing nvim treesitter parsers..."
nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
EOF

upgrade << EOF
echo "Upgrading nvim treesitter parsers..."
sudo -u pascal nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
sudo -u pascal nvim -es --cmd "lua require('nvim-treesitter').update():wait(60000)" --cmd q
EOF

symlink -u res/clang/clangd.yaml .config/clangd/config.yaml
symlink -u res/clang/format.yaml .clang-format
symlink -u res/clang/tidy.yaml .clang-tidy
symlink -u res/latexindent.yaml .config/latexindent.yaml
