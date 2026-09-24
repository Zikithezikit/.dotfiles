return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- This stops mason-lspconfig from auto-installing it
        pyright = {
          mason = false,
        },
        -- -- If you are on an older LazyVim version using ruff_lsp, add this too
        -- ruff_lsp = {
        --   mason = false,
        -- },
      },
    },
  },
}
