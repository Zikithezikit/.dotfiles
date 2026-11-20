-- basedpyright reports a work-done progress ("analyzing" -> done) after every edit, and noice renders each one as its
-- own "✔ basedpyright" popup, so typing in Python stacks a pile of them in the bottom-right corner. Hide only those;
-- progress from other servers (rust-analyzer indexing, clangd, ...) is still shown.
return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.routes = opts.routes or {}
      table.insert(opts.routes, {
        filter = {
          event = "lsp",
          kind = "progress",
          cond = function(message)
            local progress = message.opts and message.opts.progress
            return progress and progress.client == "basedpyright"
          end,
        },
        opts = { skip = true },
      })
    end,
  },
}
