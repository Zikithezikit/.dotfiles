return {
  "nvim-treesitter/nvim-treesitter", -- Attach to existing treesitter or lsp config lazy loading
  ft = { "python" }, -- Lazy-load ONLY when opening Python (.py) files
  keys = {
    {
      "<leader>cta",
      function()
        local filepath = vim.fn.expand("%:p")
        local extension = vim.fn.expand("%:e")

        -- Explicit Guard 1: Ensure it ONLY runs on .py files
        if extension ~= "py" or vim.bo.filetype ~= "python" then
          vim.notify("auto-type-annotate can only be run on .py files!", vim.log.levels.WARN)
          return
        end

        -- Explicit Guard 2: Verify binary exists in Neovim's PATH
        local bin = vim.fn.exepath("auto-type-annotate")
        if bin == "" then
          vim.notify(
            "Executable 'auto-type-annotate' not found in PATH.\nInstall with: pip install auto-type-annotate",
            vim.log.levels.ERROR
          )
          return
        end

        vim.notify("Running auto-type-annotate...", vim.log.levels.INFO)

        -- Execute asynchronously in background
        vim.fn.jobstart({ bin, filepath }, {
          stdout_buffered = true,
          stderr_buffered = true,
          on_exit = function(_, exit_code)
            if exit_code == 0 then
              vim.cmd("checktime") -- Safely reload buffer without losing undo history
              vim.notify("Successfully annotated types in " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
            else
              vim.notify(
                "auto-type-annotate failed. Ensure dmypy is running ('dmypy run') in your project root.",
                vim.log.levels.ERROR
              )
            end
          end,
        })
      end,
      ft = "python", -- Keymap strictly active on Python filetype buffers
      desc = "Auto-annotate Python Types",
    },
  },
}
