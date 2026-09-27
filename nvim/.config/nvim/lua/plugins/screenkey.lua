return {
  "NStefan002/screenkey.nvim",
  lazy = false,
  opts = {
    win_opts = {
      relative = "editor",
      anchor = "NE", -- Anchors the box by its NorthEast (top-right) corner
      row = vim.o.lines - 3, -- Sits right above the command line
      col = vim.o.columns, -- Flushed completely to the far-right edge
      width = 30,
      height = 1,
      border = "single",
    },
    compress_after = 3,
    clear_after = 3,
  },
  keys = {
    { "<leader>ts", "<cmd>Screenkey<cr>", desc = "Toggle Screenkey" },
  },
}
