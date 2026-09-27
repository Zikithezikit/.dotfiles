return {
  { "danymat/neogen", enabled = false },
  {
    "kkoomen/vim-doge",
    build = ":call doge#install()",
    -- FORCE LazyVim to aggressively bind this plugin to the literal .py extension
    -- instead of waiting for an unreliable "python" filetype detection hook
    ft = { "python" },
    init = function()
      -- Automatically hook into file reading to force "set filetype=python" on the backend
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*.py",
        callback = function()
          vim.bo.filetype = "python"
        end,
      })

      vim.g.doge_docstring_define_mappings = 0
      vim.g.doge_doc_standard_python = "google"
      vim.g.doge_python_settings = {
        omit_redundant_param_types = 0,
        single_quotes = 0,
      }
    end,
    keys = {
      {
        "<leader>cn",
        function()
          -- Bulletproof override: Mock everything the Vimscript expects right here
          vim.bo.filetype = "python"
          vim.g.did_load_filetypes = 1
          vim.b.did_ftplugin = 1

          -- Fire the generator safely
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>(doge-generate)", true, true, true), "")
        end,
        desc = "Generate Docstring (Doge)",
      },
    },
  },
}
