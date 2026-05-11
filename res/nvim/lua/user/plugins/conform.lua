require("conform").setup({
  format_after_save = {},

  formatters_by_ft = {
    c = { "clang-format" },
    cmake = { "cmake_format" },
    cpp = { "clang-format" },
    css = { "prettier-css" },
    json = { "prettier-misc" },
    jsonc = { "prettier-misc" },
    lua = { "stylua" },
    rust = { "rustfmt" },
    sh = { "shfmt" },
    xml = { "prettier-xml" },
    yaml = { "prettier-misc" },
    zsh = { "shfmt" },
  },

  formatters = {
    cmake_format = { prepend_args = { "--line-width=120", "--tab-size=2" } },
    shfmt = { prepend_args = { "--indent=2", "--case-indent", "--space-redirects" } },
    stylua = { prepend_args = { "--column-width=120", "--indent-width=2", "--indent-type=Spaces" } },

    ["prettier-misc"] = {
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
