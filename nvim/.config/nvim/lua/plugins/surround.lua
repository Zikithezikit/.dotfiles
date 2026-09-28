return {
  {
    "kylechui/nvim-surround",
    version = "*",
    -- Load on Keymap to ensure it overrides any built-in defaults
    keys = { "gz", { "S", mode = "v" } },
    config = function()
      require("nvim-surround").setup({
        keymaps = {
          insert = "<C-g>s",
          insert_line = "<C-g>S",
          normal = "gzs",
          normal_cur = "gzss",
          normal_line = "gzS",
          normal_cur_line = "gzSS",
          visual = "S",
          visual_line = "gZS",
          delete = "gzd",
          change = "gzc",
          change_line = "gzC",
        },
      })
    end,
  },
}
