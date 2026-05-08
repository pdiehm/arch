require("csvview").setup({
  view = { display_mode = "border" },

  keymaps = {
    textobject_field_inner = { "if", mode = { "x", "o" } },
    textobject_field_outer = { "af", mode = { "x", "o" } },
    jump_next_field_start = { "<Tab>", mode = "n" },
    jump_prev_field_start = { "<S-Tab>", mode = "n" },
  },
})
