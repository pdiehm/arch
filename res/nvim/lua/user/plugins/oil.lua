require("oil").setup({
  skip_confirm_for_simple_edits = true,
  use_default_keymap = false,
  view_options = { show_hidden = true },

  keymaps = {
    ["<CR>"] = "actions.select",
    ["<BS>"] = "actions.parent",
    ["q"] = "actions.close",
    ["r"] = "actions.refresh",
    ["_"] = "actions.open_cwd",
    ["~"] = "actions.cd",
  },
})

vim.keymap.set("n", "<Space><Space>", vim.cmd.Oil)
