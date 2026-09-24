return {
  {
    "binhtran432k/dracula.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "default", -- options: "default", "soft", "day"
      transparent = false,
      styles = {
        comments = { italic = true },
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
