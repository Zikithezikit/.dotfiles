return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        htmldjango = { "djlint" }, -- or "djhtml"
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        htmldjango = { "djlint" },
      },
    },
  },
  -- template completion/go-to-definition for tags, filters, urls, static
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { djlsp = { root_markers = { "manage.py" } } } },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "djlint", "django-template-lsp" } },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "htmldjango" } },
  },
  -- <leader>j: <leader>d* belongs to DAP (dr/ds/dt are its REPL/Session/Terminate)
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>j", group = "django" } } },
  },
  -- manage.py runners, only when launched from a Django project root
  {
    "folke/snacks.nvim",
    keys = (function()
      local function manage(cmd)
        return function()
          if vim.fn.filereadable("manage.py") == 1 then
            Snacks.terminal("python manage.py " .. cmd)
          else
            vim.notify("No manage.py in " .. vim.fn.getcwd(), vim.log.levels.WARN)
          end
        end
      end
      return {
        { "<leader>jr", manage("runserver"), desc = "Django runserver" },
        { "<leader>jm", manage("migrate"), desc = "Django migrate" },
        { "<leader>jM", manage("makemigrations"), desc = "Django makemigrations" },
        { "<leader>jt", manage("test"), desc = "Django test" },
        { "<leader>js", manage("shell"), desc = "Django shell" },
      }
    end)(),
  },
}
