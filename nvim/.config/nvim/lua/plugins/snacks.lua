return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        hidden = true, -- Apply to all pickers
        sources = {
          files = {
            hidden = true, -- Show hidden/dotfiles in fuzzy finder
            -- ignored = false, -- Respect .gitignore
          },
          explorer = {
            hidden = true, -- Show hidden files in file explorer
          },
          grep = {
            hidden = true, -- Search hidden files
          },
        },
      },
      image = {
        enabled = true, -- Enable image preview
      },
    },
  },
}
