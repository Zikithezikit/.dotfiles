-- lazyvim.plugins.extras.lang.sql wires sqlfluff in two ways that break outside a sqlfluff project:
--  * conform's builtin formatter needs a project config file (.sqlfluff, pyproject.toml, ...) or it never runs
--  * the extra forces --dialect=ansi on the command line, which would override a project's own dialect
-- Dialect now comes from sqlfluff's own config: a project .sqlfluff wins, else ~/.sqlfluff (ansi, stowed from
-- sqlfluff/ in the dotfiles). sqlfluff itself is installed with `uv tool install sqlfluff`, Mason cannot on Python 3.14.
return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.sqlfluff = { require_cwd = false, args = { "format", "-" } }
    end,
  },
}
