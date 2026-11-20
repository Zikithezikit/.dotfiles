-- <leader>gg (lazygit, uses delta via ~/.config/lazygit) and gitsigns come from LazyVim; diffview adds
-- side-by-side diffs, a changed-files panel and file history.
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview (working tree)" },
      { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
    },
    opts = {},
  },

  -- Telescope git previews run plain `git --no-pager diff` into a buffer, so delta never applies.
  -- Run git in a terminal instead (git then invokes core.pager = delta).
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      local previewers = require("telescope.previewers")
      local git = { "git", "-c", "delta.paging=never", "-c", "diff.mnemonicPrefix=false" }
      local function delta(get_args)
        return previewers.new_termopen_previewer({
          get_command = function(entry)
            return vim.list_extend(vim.deepcopy(git), get_args(entry))
          end,
        })
      end
      local show = delta(function(e)
        return { "show", e.value }
      end)
      opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, {
        git_commits = { previewer = show },
        git_bcommits = { previewer = show },
        git_status = {
          previewer = delta(function(e)
            if e.status == "??" then -- untracked: diff against nothing so the whole file shows as added
              return { "diff", "--no-index", "--", "/dev/null", e.value }
            end
            return { "diff", "HEAD", "--", e.value } -- staged + unstaged together
          end),
        },
      })
    end,
  },
}
