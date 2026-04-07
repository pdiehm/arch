vim.diagnostic.config({
  severity_sort = true,
  virtual_lines = { current_line = true },
  virtual_text = { current_line = false },
})

vim.keymap.set("n", "gp", function()
  vim.diagnostic.jump({ count = 1 })
end)

vim.keymap.set("n", "gP", function()
  vim.diagnostic.jump({ count = -1 })
end)

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user.lsp", { clear = true }),

  callback = function()
    local ts = require("telescope.builtin")
    vim.keymap.set("n", "ga", vim.lsp.buf.code_action)
    vim.keymap.set("n", "gd", ts.lsp_definitions)
    vim.keymap.set("n", "gi", ts.lsp_implementations)

    vim.keymap.set("n", "gk", function()
      ts.lsp_references({ include_current_line = true })
    end)

    vim.keymap.set("n", "gr", function()
      vim.ui.input({ prompt = "New Name: " }, function(name)
        vim.lsp.buf.rename(name)
      end)
    end)
  end,
})
