require("conform").setup({
  format_after_save = {},

  formatters_by_ft = {
    bib = { "bibtex-tidy" },
    c = { "clang-format" },
    cmake = { "cmake_format" },
    cpp = { "clang-format" },
    css = { "prettier-css" },
    dockerfile = { "dockerfmt" },
    html = { "prettier" },
    java = { "google-java-format" },
    javascript = { "prettier-js" },
    javascriptreact = { "prettier-js" },
    json = { "prettier-cfg" },
    jsonc = { "prettier-cfg" },
    lua = { "stylua" },
    markdown = { "prettier" },
    nix = { "nixfmt" },
    php = { "prettier-php" },
    python = { "isort", "black" },
    rust = { "rustfmt" },
    sh = { "shfmt" },
    tex = { "latexindent" },
    typescript = { "prettier-js" },
    typescriptreact = { "prettier-js" },
    xml = { "prettier-xml" },
    yaml = { "prettier-cfg" },
    zsh = { "shfmt" },
  },

  formatters = {
    black = { prepend_args = { "--line-length=120" } },
    cmake_format = { prepend_args = { "--line-width=120", "--tab-size=2" } },
    dockerfmt = { prepend_args = { "--indent=2", "--newline", "--space-redirects" } },
    latexindent = { prepend_args = { "--local=/home/pascal/.config/latexindent.yaml", "--logfile=/dev/null" } },
    nixfmt = { prepend_args = { "--width=120", "--indent=2", "--strict" } },
    prettier = { prepend_args = { "--print-width=120", "--tab-width=2" } },
    shfmt = { prepend_args = { "--indent=2", "--case-indent", "--space-redirects" } },
    stylua = { prepend_args = { "--column-width=120", "--indent-width=2", "--indent-type=Spaces" } },

    ["bibtex-tidy"] = {
      prepend_args = {
        "--wrap=120",
        "--space=2",
        "--numeric",
        "--blank-lines",
        "--sort",
        "--merge",
        "--no-escape",
        "--sort-fields",
        "--trailing-commas",
        "--remove-empty-fields",
      },
    },

    ["prettier-js"] = {
      inherit = "prettier",

      prepend_args = {
        "--plugin=/usr/lib/node_modules/prettier-plugin-organize-imports/index.js",
        "--print-width=120",
        "--tab-width=2",
        "--arrow-parens=avoid",
      },
    },

    ["prettier-cfg"] = {
      inherit = "prettier",
      prepend_args = { "--print-width=120", "--tab-width=2", "--trailing-comma=none" },
    },

    ["prettier-css"] = {
      inherit = "prettier",

      prepend_args = {
        "--plugin=/usr/lib/node_modules/prettier-plugin-css-order/src/main.mjs",
        "--print-width=120",
        "--tab-width=2",
      },
    },

    ["prettier-php"] = {
      inherit = "prettier",

      prepend_args = {
        "--plugin=/usr/lib/node_modules/@prettier/plugin-php/standalone.js",
        "--print-width=120",
        "--tab-width=2",
        "--brace-style=1tbs",
      },
    },

    ["prettier-xml"] = {
      inherit = "prettier",

      prepend_args = {
        "--plugin=/usr/lib/node_modules/@prettier/plugin-xml/src/plugin.js",
        "--print-width=120",
        "--tab-width=2",
      },
    },
  },
})
