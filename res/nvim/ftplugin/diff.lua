vim.keymap.set("x", "x", ":silent! substitute/^-/ /<CR>gv:silent! global/^+/d<CR>", { buf = 0 })
vim.keymap.set("n", "x", "Vx", { buf = 0, remap = true })
