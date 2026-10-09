package neovim vim-spell-de nvim-plugins-pd \
  {bash,cmake,dockerfile,eslint,java,lua,tailwindcss,typescript,yaml}-language-server \
  vscode-{css,html,json}-languageserver python-{lsp-server,black,isort} \
  clang nixd phpactor rust-analyzer shellcheck texlab \
  prettier prettier-plugin-{css-order,organize-imports,php,xml} \
  bibtex-tidy cmake-format dockerfmt google-java-format nixfmt shfmt stylua

symlink -u res/nvim .config/nvim
write -au .config/dropin/env.sh "EDITOR=nvim"

symlink -u res/clangd .config/clangd
symlink -u res/latexindent.yaml .config/latexindent.yaml
