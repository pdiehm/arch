local telescope = require("telescope")
local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

telescope.setup({
  defaults = {
    file_ignore_patterns = { "^.git/" },
    layout_strategy = "flex",

    default_mappings = {
      i = {
        ["<Esc>"] = actions.close,
        ["<Return>"] = actions.select_default,
        ["<S-Return>"] = actions.select_vertical,
        ["<A-Return>"] = actions.select_tab,
        ["<Up>"] = actions.move_selection_worse,
        ["<Down>"] = actions.move_selection_better,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<A-q>"] = actions.smart_send_to_qflist,
        ["<A-Q>"] = actions.smart_add_to_qflist,
      },
    },

    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--hidden",
      "--pcre2",
    },
  },
})

telescope.load_extension("ui-select")

local function map(key, picker, opts)
  vim.keymap.set("n", "<Space>" .. key, function()
    builtin[picker](opts)
  end)
end

map("a", "spell_suggest")
map("b", "buffers")
map("c", "git_commits")
map("d", "lsp_document_symbols")
map("f", "find_files", { hidden = true })
map("g", "live_grep")
map("h", "help_tags")
map("j", "jumplist")
map("k", "grep_string")
map("l", "resume")
map("m", "man_pages")
map("o", "vim_options")
map("p", "diagnostics")
map("q", "quickfix")
map("s", "git_status", { expand_dir = true })
map("v", "git_bcommits")
map("w", "lsp_workspace_symbols")
map("x", "current_buffer_fuzzy_find")
map("z", "git_stash")
map(":", "command_history")
map("/", "search_history")
