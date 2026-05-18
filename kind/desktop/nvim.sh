package neovim vim-spell-de tree-sitter-cli \
  clang rust-analyzer yaml-language-server \
  bash-language-server shellcheck shfmt \
  cmake-language-server cmake-format \
  dockerfile-language-server dockerfmt \
  java-language-server google-java-format \
  lua-language-server stylua \
  nixd nixfmt \
  phpactor prettier-plugin-php \
  python-lsp-server python-black python-isort \
  texlab bibtex-tidy \
  typescript-language-server eslint-language-server \
  prettier prettier-plugin-css-order prettier-plugin-xml \
  vscode-css-languageserver vscode-html-languageserver vscode-json-languageserver

symlink -u res/nvim .config/nvim
write -au .config/env.sh "EDITOR=nvim"

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
