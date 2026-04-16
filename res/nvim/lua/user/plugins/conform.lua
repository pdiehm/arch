require("conform").setup({
  format_after_save = {},

  formatters_by_ft = {
    css = { "prettier-css" },
    json = { "prettier-json" },
    jsonc = { "prettier-json" },
    lua = { "stylua" },
    sh = { "shfmt" },
    zsh = { "shfmt" },
  },

  formatters = {
    shfmt = { prepend_args = { "--indent=2", "--case-indent", "--space-redirects" } },
    stylua = { prepend_args = { "--column-width=120", "--indent-type=Spaces", "--indent-width=2" } },

    ["prettier-css"] = {
      inherit = "prettier",
      prepend_args = { "--plugin=/usr/lib/node_modules/prettier-plugin-css-order/src/main.mjs", "--print-width=120" },
    },

    ["prettier-json"] = {
      inherit = "prettier",
      prepend_args = { "--print-width=120", "--trailing-comma=none" },
    },
  },
})
