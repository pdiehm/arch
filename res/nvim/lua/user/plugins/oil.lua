require("oil").setup({
  skip_confirm_for_simple_edits = true,
  use_default_keymap = false,
  view_options = { show_hidden = true },

  keymaps = {
    ["<Return>"] = "actions.select",
    ["<BS>"] = "actions.parent",
    ["q"] = "actions.close",
    ["r"] = "actions.refresh",
    ["_"] = "actions.open_cwd",
    ["~"] = "actions.cd",
    ["1"] = { "1j<CR>", remap = true },
    ["2"] = { "2j<CR>", remap = true },
    ["3"] = { "3j<CR>", remap = true },
    ["4"] = { "4j<CR>", remap = true },
    ["5"] = { "5j<CR>", remap = true },
    ["6"] = { "6j<CR>", remap = true },
    ["7"] = { "7j<CR>", remap = true },
    ["8"] = { "8j<CR>", remap = true },
    ["9"] = { "9j<CR>", remap = true },
  },
})

vim.keymap.set("n", "<Space><Space>", vim.cmd.Oil)
