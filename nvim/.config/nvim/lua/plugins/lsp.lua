return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Keep basedpyright enabled as your main language server
        basedpyright = {},

        -- 1. Disable jedi completely to stop the overlapping features
        jedi_language_server = {
          enabled = false,
        },

        -- 2. Prevent ruff from duplicating the statusline symbols
        ruff = {
          on_attach = function(client, _)
            if client.name == "ruff" then
              client.server_capabilities.documentSymbolProvider = false
            end
          end,
        },
      },
    },
  },
}
