vim.api.nvim_create_autocmd("TermOpen", { command = "setlocal nospell" })
vim.api.nvim_create_autocmd("TermClose", { command = "bdelete" })
