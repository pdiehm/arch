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

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      check = {
        command = "clippy",
      },
    },
  },
})

vim.lsp.enable("bashls")
vim.lsp.enable("clangd")
vim.lsp.enable("cmake")
vim.lsp.enable("cssls")
vim.lsp.enable("dockerls")
vim.lsp.enable("eslint")
vim.lsp.enable("html")
vim.lsp.enable("java_language_server")
vim.lsp.enable("jsonls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("nixd")
vim.lsp.enable("phpactor")
vim.lsp.enable("pylsp")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("texlab")
vim.lsp.enable("ts_ls")
vim.lsp.enable("yamlls")
