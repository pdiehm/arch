local user = vim.api.nvim_create_augroup("user", { clear = true })

vim.api.nvim_create_autocmd("TermOpen", { command = "setlocal nospell", group = user })
vim.api.nvim_create_autocmd("TermClose", { command = "bdelete", group = user })

vim.api.nvim_create_autocmd("FileType", {
  group = user,

  callback = function()
    if pcall(vim.treesitter.start) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
