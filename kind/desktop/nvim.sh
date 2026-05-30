package neovim vim-spell-de tree-sitter-cli \
  bash-language-server shellcheck shfmt \
  clang rust-analyzer yaml-language-server \
  cmake-language-server cmake-format \
  dockerfile-language-server dockerfmt \
  java-language-server google-java-format \
  lua-language-server stylua \
  nixd nixfmt \
  phpactor prettier-plugin-php \
  python-lsp-server python-black python-isort \
  texlab bibtex-tidy \
  prettier prettier-plugin-css-order prettier-plugin-xml \
  typescript-language-server eslint-language-server tailwindcss-language-server \
  vscode-css-languageserver vscode-html-languageserver vscode-json-languageserver

symlink -u res/nvim .config/nvim
dropin env.sh "EDITOR=nvim"

script -u << EOF
echo "Setting up neovim..."
git -C .config/syscfg pull --recurse-submodules=on-demand
nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
EOF

upgrade << EOF
echo "Setting up neovim..."
sudo -u pascal nvim -es --cmd "lua require('nvim-treesitter').install({ 'stable', 'unstable' }):wait(60000)" --cmd q
sudo -u pascal nvim -es --cmd "lua require('nvim-treesitter').update():wait(60000)" --cmd q
EOF

symlink -u res/clang/clangd.yaml .config/clangd/config.yaml
symlink -u res/clang/format.yaml .clang-format
symlink -u res/clang/tidy.yaml .clang-tidy
symlink -u res/latexindent.yaml .config/latexindent.yaml
