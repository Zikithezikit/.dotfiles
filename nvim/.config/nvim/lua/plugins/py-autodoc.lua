return {
  "ok97465/py-autodoc.nvim",
  ft = "python", -- Load only when opening Python files (Lazy loading)
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- Required for parsing Python structures
  },
  config = function()
    require("py-autodoc").setup({
      -- Add custom configuration options here if needed
    })
  end,
  -- Optional: Set keymaps to generate docstrings
  keys = {
    {
      "<leader>pd",
      function()
        require("py-autodoc").generate()
      end,
      desc = "Generate Python Docstring",
      ft = "python",
    },
  },
}
