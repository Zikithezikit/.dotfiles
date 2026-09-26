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
}
