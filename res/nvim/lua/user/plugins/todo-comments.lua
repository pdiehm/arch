require("todo-comments").setup({
  highlight = { after = "", keyword = "fg" },
  search = { args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--hidden" } },
})

vim.keymap.set("n", "<Space>t", vim.cmd.TodoTelescope)
