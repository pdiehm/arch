package neovim vim-spell-de nvim-plugins-pd \
  clang rust-analyzer yaml-language-server \
  prettier prettier-plugin-css-order prettier-plugin-organize-imports prettier-plugin-xml \
  typescript-language-server eslint-language-server tailwindcss-language-server \
  vscode-css-languageserver vscode-html-languageserver vscode-json-languageserver \
  bash-language-server shellcheck shfmt \
  cmake-language-server cmake-format \
  dockerfile-language-server dockerfmt \
  lua-language-server stylua \
  nixd nixfmt \
  phpactor prettier-plugin-php \
  python-lsp-server python-black python-isort \
  texlab bibtex-tidy

symlink -u res/nvim .config/nvim
dropin env.sh "EDITOR=nvim"

symlink -u res/clang/clangd.yaml .config/clangd/config.yaml
symlink -u res/clang/format.yaml .clang-format
symlink -u res/clang/tidy.yaml .clang-tidy
symlink -u res/latexindent.yaml .config/latexindent.yaml
