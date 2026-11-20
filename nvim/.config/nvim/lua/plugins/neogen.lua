-- Docstrings for every language via treesitter: <leader>cn (python/ts/c/cpp/lua/...). Replaces vim-doge + py-autodoc.
return {
  {
    "danymat/neogen",
    -- neogen's TS auto-detect treats every function_declaration as a class (emits @class); ask for a function
    -- doc first and fall back to auto-detect only if nothing matched (class, interface, type, ...).
    keys = {
      {
        "<leader>cn",
        function()
          local neogen, tick = require("neogen"), vim.b.changedtick
          vim.cmd("normal! ^")
          local node = vim.treesitter.get_node()
          local exp = node and (node:type() == "export_statement" and node or node:parent())
          local decl = exp and exp:type() == "export_statement" and exp:field("declaration")[1]
          if decl then -- cursor on the `export` keyword: step into the declaration
            local row, col = decl:start()
            vim.api.nvim_win_set_cursor(0, { row + 1, col })
          end
          neogen.generate({ type = "func" })
          if vim.b.changedtick == tick then
            neogen.generate()
          end
        end,
        ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        desc = "Generate Annotations (Neogen)",
      },
    },
    opts = {
      languages = {
        python = { template = { annotation_convention = "google_docstrings" } },
        c = { template = { annotation_convention = "doxygen" } },
        cpp = { template = { annotation_convention = "doxygen" } },
        typescript = { template = { annotation_convention = "jsdoc" } },
      },
    },
  },
}
