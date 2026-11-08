return {
  "saghen/blink.cmp",
  dependencies = { "milanglacier/minuet-ai.nvim" },
  opts = function(_, opts)
    opts.keymap = vim.tbl_extend("force", opts.keymap or {}, {
      preset = "default",
      ["<Tab>"] = { "accept", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      -- manual trigger: minuet only queries on this key, results sit on top of the normal sources
      ["<C-Space>"] = {
        function(cmp)
          -- show() is a no-op while the menu is open, so reopen it as a manual request
          cmp.hide()
          vim.schedule(cmp.show)
          return true
        end,
      },
    })
    opts.sources = opts.sources or {}
    opts.sources.default = vim.list_extend(vim.deepcopy(opts.sources.default or {}), { "minuet" })
    opts.sources.providers = opts.sources.providers or {}
    opts.sources.providers.minuet = {
      name = "minuet",
      module = "minuet.blink",
      async = true,
      timeout_ms = 3000,
      score_offset = 100, -- keep Gemini above lsp/buffer items
    }
    opts.completion = opts.completion or {}
    opts.completion.trigger = vim.tbl_extend("force", opts.completion.trigger or {}, { prefetch_on_insert = false })
  end,
}
