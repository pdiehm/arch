require("todo-comments").setup({
  search = { args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--hidden" } },

  highlight = {
    after = "",
    keyword = "fg",
  },
})

vim.keymap.set("n", "<Space>t", vim.cmd.TodoTelescope)
