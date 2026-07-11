vim.keymap.set("x", "x", ":silent! substitute/^-/ /<CR>gv:silent! global/^+/d<CR>")
vim.keymap.set("n", "x", "Vx", { remap = true })
