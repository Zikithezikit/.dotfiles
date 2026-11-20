-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Prefer basedpyright (better than stock pyright for many people)
vim.g.lazyvim_python_lsp = "basedpyright"
-- Modern Ruff (not the old ruff_lsp)
vim.g.lazyvim_python_ruff = "ruff"

-- Pickers, grep, terminals etc. use LazyVim.root(); default is LSP root -> .git -> cwd, which climbs to a parent
-- of the folder nvim was launched in. Always use the launch folder.
vim.g.root_spec = { "cwd" }
