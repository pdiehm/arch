local cmp = require("cmp")

local function map(primary, secondary)
  return function(fallback)
    if cmp.visible() then
      primary()
    else
      (secondary or fallback)()
    end
  end
end

cmp.setup({
  preselect = cmp.PreselectMode.None,
  sources = { { name = "nvim_lsp" }, { name = "path" }, { name = "buffer" } },

  formatting = {
    fields = { "icon", "abbr" },
    format = require("lspkind").cmp_format(),
  },

  mapping = {
    ["<C-Space>"] = map(cmp.mapping.close(), cmp.mapping.complete()),
    ["<C-Return>"] = map(cmp.mapping.confirm({ select = true })),
    ["<Tab>"] = map(cmp.mapping.select_next_item()),
    ["<S-Tab>"] = map(cmp.mapping.select_prev_item()),
    ["<C-d>"] = map(cmp.mapping.scroll_docs(8)),
    ["<C-u>"] = map(cmp.mapping.scroll_docs(-8)),
    ["<C-c>"] = map(cmp.mapping.abort()),
  },
})

vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
