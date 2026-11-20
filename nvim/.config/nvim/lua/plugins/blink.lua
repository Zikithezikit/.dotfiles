return {
  "saghen/blink.cmp",
  dependencies = vim.fn.executable("claude") == 1 and { "milanglacier/minuet-ai.nvim" } or nil,
  opts = function(_, opts)
    opts.keymap = vim.tbl_extend("force", opts.keymap or {}, {
      preset = "default",
      -- menu item first; otherwise accept the Haiku ghost text if one is showing; otherwise a normal <Tab>
      ["<Tab>"] = {
        "accept",
        function()
          local ok, vt = pcall(require, "minuet.virtualtext")
          if ok and vt.action.is_visible() then
            vt.action.accept()
            return true
          end
        end,
        "fallback",
      },
      ["<CR>"] = { "accept", "fallback" },
      -- Ctrl+Space opens the menu as usual; with the AI menu switch on (<A-a>, <leader>am) it also asks Haiku and
      -- puts the result on top
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
    if vim.fn.executable("claude") ~= 1 then
      return -- no claude CLI: keep plain LSP/buffer completion, <C-Space> above still works
    end
    opts.sources.default = vim.list_extend(vim.deepcopy(opts.sources.default or {}), { "minuet" })
    opts.sources.providers = opts.sources.providers or {}
    opts.sources.providers.minuet = {
      name = "minuet",
      module = "minuet.blink",
      async = true,
      timeout_ms = 3000,
      score_offset = 100, -- keep Haiku above lsp/buffer items
      -- while the AI menu switch is off the source is skipped, so no request is made when the menu opens
      enabled = function()
        return vim.g.haiku_menu
      end,
    }
    opts.completion = opts.completion or {}
    -- multi-line Haiku items show as ghost text below the cursor; the menu is placed once when it opens
    -- (not per selection), so always open it above to keep it off the ghost text
    opts.completion.menu = vim.tbl_extend("force", opts.completion.menu or {}, {
      direction_priority = { "n", "s" },
    })
    opts.completion.trigger = vim.tbl_extend("force", opts.completion.trigger or {}, { prefetch_on_insert = false })
  end,
}
