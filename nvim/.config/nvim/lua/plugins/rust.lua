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
    opts = { spec = { { "<leader>r", group = "rust", icon = "" } } },
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
