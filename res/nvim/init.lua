require("user.options")
require("user.keymaps")
require("user.autocmds")
require("user.lsp")
require("user.plugins")

require("onedark").setup({ term_colors = false, transparent = true })
vim.cmd.colorscheme("onedark")
