vim.lsp.config("bashls", {
  filetypes = { "bash", "sh", "zsh" },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { library = { vim.env.VIMRUNTIME } },
    },
  },
})

vim.lsp.enable("bashls")
vim.lsp.enable("cssls")
vim.lsp.enable("jsonls")
vim.lsp.enable("lua_ls")
