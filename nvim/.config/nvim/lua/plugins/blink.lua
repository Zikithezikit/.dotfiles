return {
  "saghen/blink.cmp",
  dependencies = vim.env.GEMINI_API_KEY and { "milanglacier/minuet-ai.nvim" } or nil,
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
    if not vim.env.GEMINI_API_KEY then
      return -- no key: keep plain LSP/buffer completion, <C-Space> above still works
    end
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
    -- multi-line Gemini items show as ghost text below the cursor; the menu is placed once when it opens
    -- (not per selection), so always open it above to keep it off the ghost text
    opts.completion.menu = vim.tbl_extend("force", opts.completion.menu or {}, {
      direction_priority = { "n", "s" },
    })
    opts.completion.trigger = vim.tbl_extend("force", opts.completion.trigger or {}, { prefetch_on_insert = false })
  end,
}
