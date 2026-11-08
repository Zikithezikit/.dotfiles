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
    opts = { servers = { djlsp = { root_markers = { "manage.py" } }, djls = { enabled = false } } }, -- djls duplicates djlsp
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "djlint", "django-template-lsp" } },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "htmldjango" } },
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
        { "<leader>dr", manage("runserver"), desc = "Django runserver" },
        { "<leader>dm", manage("migrate"), desc = "Django migrate" },
        { "<leader>dM", manage("makemigrations"), desc = "Django makemigrations" },
        { "<leader>dt", manage("test"), desc = "Django test" },
        { "<leader>ds", manage("shell"), desc = "Django shell" },
      }
    end)(),
  },
}
