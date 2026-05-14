vim.diagnostic.config({
  jump = { on_jump = vim.diagnostic.open_float },
  severity_sort = true,
  virtual_text = true,
})

vim.keymap.set("n", "gp", function()
  vim.diagnostic.jump({ count = 1 })
end)

vim.keymap.set("n", "gP", function()
  vim.diagnostic.jump({ count = -1 })
end)

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    local ts = require("telescope.builtin")
    vim.keymap.set("n", "<Space>d", ts.lsp_document_symbols)
    vim.keymap.set("n", "<Space>w", ts.lsp_workspace_symbols)
    vim.keymap.set("n", "gd", ts.lsp_definitions)
    vim.keymap.set("n", "gi", ts.lsp_implementations)
    vim.keymap.set("n", "gr", ts.lsp_references)
    vim.keymap.set("n", "gt", ts.lsp_type_definitions)
    vim.keymap.set("n", "za", vim.lsp.buf.code_action)

    vim.keymap.set("n", "zr", function()
      vim.ui.input({ prompt = "New Name: " }, function(name)
        vim.lsp.buf.rename(name)
      end)
    end)
  end,
})
