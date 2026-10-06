package neovim vim-spell-de nvim-plugins-pd \
  {bash,cmake,dockerfile,eslint,lua,tailwindcss,typescript,yaml}-language-server \
  vscode-{css,html,json}-languageserver python-{lsp-server,black,isort} \
  clang nixd phpactor rust-analyzer shellcheck texlab \
  prettier prettier-plugin-{php,xml,css-order,organize-imports} \
  bibtex-tidy cmake-format dockerfmt nixfmt shfmt stylua

symlink -u res/nvim .config/nvim
write -au .config/dropin/env.sh "EDITOR=nvim"

symlink -u res/clangd .config/clangd
symlink -u res/latexindent.yaml .config/latexindent.yaml
