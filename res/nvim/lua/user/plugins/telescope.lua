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

telescope.load_extension("fzf")
telescope.load_extension("ui-select")

local function map(key, picker, opts)
  vim.keymap.set("n", key, function()
    builtin[picker](opts)
  end)
end

map("<Space>a", "builtin")
map("<Space>b", "buffers")
map("<Space>c", "git_commits")
map("<Space>f", "find_files", { hidden = true })
map("<Space>g", "live_grep")
map("<Space>h", "help_tags")
map("<Space>j", "jumplist")
map("<Space>k", "grep_string")
map("<Space>l", "resume")
map("<Space>m", "man_pages")
map("<Space>o", "vim_options")
map("<Space>p", "diagnostics")
map("<Space>q", "quickfix")
map("<Space>s", "git_status", { expand_dir = true })
map("<Space>v", "git_bcommits")
map("<Space>x", "current_buffer_fuzzy_find")
map("<Space>z", "git_stash")
map("<Space>:", "command_history")
map("<Space>/", "search_history")
map("zs", "spell_suggest")
