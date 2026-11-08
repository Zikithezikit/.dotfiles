return {
  "saghen/blink.cmp",
  dependencies = { "milanglacier/minuet-ai.nvim" },
  opts = function(_, opts)
    opts.keymap = vim.tbl_extend("force", opts.keymap or {}, {
      preset = "default",
      ["<Tab>"] = { "accept", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      -- ask minuet (Gemini) only; <C-n>/<C-p> cycle and Tab/Enter accept like any item
      ["<C-Space>"] = require("minuet").make_blink_map(),
    })
    opts.sources = opts.sources or {}
    opts.sources.providers = opts.sources.providers or {}
    opts.sources.providers.minuet = {
      name = "minuet",
      module = "minuet.blink",
      async = true,
      timeout_ms = 3000,
      score_offset = 50,
    }
    opts.completion = opts.completion or {}
    opts.completion.trigger = vim.tbl_extend("force", opts.completion.trigger or {}, { prefetch_on_insert = false })
  end,
}
