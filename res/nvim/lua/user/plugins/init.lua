require("user.plugins.cmp")
require("user.plugins.conform")
require("user.plugins.csvview")
require("user.plugins.lsp")
require("user.plugins.oil")
require("user.plugins.telescope")
require("user.plugins.todo-comments")

require("nvim-autopairs").setup()
require("nvim-ts-autotag").setup()

require("gitsigns").setup({
  current_line_blame = true,
  current_line_blame_opts = { delay = 250 },
})

require("lualine").setup({
  options = { always_show_tabline = false },
  sections = { lualine_x = { "lsp_status", "filetype" } },
  tabline = { lualine_a = { { "tabs", mode = 1 } } },
})

require("toggleterm").setup({
  open_mapping = "<A-Return>",
  size = 8,
})
