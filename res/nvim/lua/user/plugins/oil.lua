require("oil").setup({
  skip_confirm_for_simple_edits = true,
  use_default_keymap = false,
  view_options = { show_hidden = true },

  keymaps = {
    ["<Return>"] = "actions.select",
    ["<BS>"] = "actions.parent",
    ["q"] = "actions.close",
    ["_"] = "actions.open_cwd",
    ["~"] = "actions.cd",
  },
})

vim.keymap.set("n", "<Space><Space>", "<Cmd>Oil<CR>")
