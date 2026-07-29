require("blink.cmp").setup({
  cmdline = { enabled = false },
  signature = { enabled = true },

  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 0,
    },

    list = {
      selection = {
        preselect = false,
      },
    },
  },

  keymap = {
    preset = "none",
    ["<C-Space>"] = { "show", "hide" },
    ["<A-Space>"] = { "show_signature", "hide_signature", "fallback" },
    ["<C-Return>"] = { "select_and_accept", "fallback" },
    ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
    ["<C-u>"] = { "scroll_signature_up", "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_signature_down", "scroll_documentation_down", "fallback" },
    ["<C-c>"] = { "cancel", "fallback" },
  },

  sources = {
    default = { "omni", "lsp", "path", "snippets", "buffer" },

    providers = {
      omni = {
        fallbacks = { "lsp", "path", "snippets", "buffer" },

        enabled = function()
          return not vim.list_contains({ "", "v:lua.vim.lsp.omnifunc" }, vim.bo.omnifunc)
        end,
      },

      path = {
        opts = {
          show_hidden_files_by_default = true,
        },
      },
    },
  },
})
