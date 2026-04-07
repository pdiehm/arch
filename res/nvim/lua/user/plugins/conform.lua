require("conform").setup({
  format_after_save = {},

  formatters_by_ft = {
    lua = { "stylua" },
    sh = { "shfmt" },
    zsh = { "shfmt" },
  },

  formatters = {
    shfmt = { prepend_args = { "--indent=2", "--case-indent", "--space-redirects" } },
    stylua = { prepend_args = { "--column-width=120", "--indent-type=Spaces", "--indent-width=2" } },
  },
})
