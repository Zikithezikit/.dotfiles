return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            check = { command = "clippy" }, -- LazyVim only turns checkOnSave on; this makes it run clippy, not `cargo check`
            -- own target dir: `cargo run/build` in a terminal no longer blocks on rust-analyzer's build lock
            cargo = { targetDir = true },
          },
        },
      },
    },
  },

  -- rustaceanvim commands that have no default keys (cR = code action and dr = debuggables come from LazyVim)
  {
    "folke/which-key.nvim",
    -- 0xf1617 = nf-md-language_rust
    opts = function(_, opts)
      local icon = { icon = vim.fn.nr2char(0xf1617), color = "orange" }
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>r", group = "rust", icon = icon })
      for _, key in ipairs({ "r", "t", "e", "p", "d", "c" }) do
        table.insert(opts.spec, { "<leader>r" .. key, icon = icon })
      end
    end,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "rust", "toml" },
        callback = function(ev)
          local function map(lhs, cmd, desc)
            vim.keymap.set("n", lhs, function() vim.cmd.RustLsp(cmd) end, { buffer = ev.buf, desc = desc })
          end
          map("<leader>rr", "runnables", "Rust runnables")
          map("<leader>rt", "testables", "Rust testables")
          map("<leader>re", "expandMacro", "Expand macro")
          map("<leader>rp", "parentModule", "Parent module")
          map("<leader>rd", "openDocs", "Open docs.rs")
          map("<leader>rc", "openCargo", "Open Cargo.toml")
        end,
      })
    end,
  },
}
