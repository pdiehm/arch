vim.api.nvim_create_autocmd("TermOpen", { command = "setlocal nospell" })
vim.api.nvim_create_autocmd("TermClose", { command = "bdelete" })

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
