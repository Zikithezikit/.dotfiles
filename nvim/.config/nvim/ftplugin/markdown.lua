-- Markdown buffer-local settings and keymaps.
--
-- Sourced by Neovim's own filetype detection, so it applies to the first buffer of a session.
-- A FileType autocmd in lua/config/autocmds.lua would not: that file is sourced on the VeryLazy
-- event, which fires after the first file has been read and its FileType event has already gone
-- out, so under `nvim <file>` the autocmd would never run for the only buffer that exists.
-- (Obsidian's <leader>o* keymaps do not have this problem -- lazy.nvim declares ft = "markdown",
-- which loads the plugin and applies its keys on that same first FileType event.)
--
-- These mappings are buffer-local and belong here rather than in the obsidian.nvim spec's `keys`
-- table for the same reason: `buffer = true` entries in a `lazy = true` spec never materialise.
-- Verified by defining them there and finding no [o / ]o / <CR> in `nvim_buf_get_keymap` at all,
-- whether the plugin was loaded by its filetype trigger or force-loaded.

-- Give folded notes a readable summary line instead of the raw first line.
--
-- LazyVim sets `foldtext = ""` globally and opts LSP-attached buffers into `foldmethod = "expr"`
-- with an LSP or treesitter `foldexpr` (LazyVim lsp/init.lua:196, treesitter.lua:131), so folding
-- already works in the vault without anything here. What was missing is the display half: with
-- foldtext empty, a closed fold renders as the bare first line, so a folded `## Key ideas` section
-- and a folded frontmatter block look alike and nothing signals that content is hidden.
-- vim.lsp.foldtext() appends the line count and a mid-ellipsis.
--
-- foldmethod and foldexpr are deliberately not set. LazyVim's set_default() claims them on a
-- first-wins basis, and which of the two providers wins depends on attach order; overriding
-- either here would silently disable folding ranges from the other.
vim.opt_local.foldtext = "v:lua.vim.lsp.foldtext()"

-- <CR> and [o / ]o below replace the plugin's own, which lua/plugins/obsidian.lua switches off by
-- setting vim.g.obsidian_default_keymap = false (obsidian.nvim autocmds.lua:62-71). That switch
-- is what makes these take effect cleanly; without it the plugin's BufEnter autocmd would rebind
-- the same keys in the same buffer.

vim.keymap.set("n", "<CR>", function()
  require("obsidian.actions").smart_action()
end, { buffer = true, expr = true, desc = "Obsidian: Smart action" })

---@param direction "next"|"prev"
local function nav_link_wrap(direction)
  local Note = require "obsidian.note"

  local note = Note.from_buffer(0)
  if not note then
    return
  end

  -- The same match list nav_link builds: real links, plus cache-backed link suggestions when the
  -- cache is on, i.e. the include_hints = true the plugin's own bindings pass.
  local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  local matches = vim.tbl_map(function(link)
    return { line = link.line, start = link.start }
  end, note:links())
  if require("obsidian.cache").is_enabled() then
    for _, hint in ipairs(note:link_suggestions()) do
      matches[#matches + 1] = { line = hint.range.start_row + 1, start = hint.range.start_col }
    end
  end
  if #matches == 0 then
    return
  end
  table.sort(matches, function(a, b)
    return a.line < b.line or (a.line == b.line and a.start < b.start)
  end)

  -- First match strictly ahead of the cursor, else wrap around to the first/last one.
  local target
  for _, m in ipairs(matches) do
    if direction == "next" and ((m.line > cursor_line) or (cursor_line == m.line and cursor_col < m.start)) then
      target = m
      break
    end
  end
  if not target then
    target = direction == "next" and matches[1] or matches[#matches]
  end

  vim.api.nvim_win_set_cursor(0, { target.line, target.start })
end

-- [o / ]o gain something the plugin's do not have: they wrap.
--
-- Upstream issue #745. nav_link (obsidian.nvim actions.lua:124) scans in one direction and
-- `return`s only on a match past the cursor; past the last link there is nothing to return, so
-- the cursor does not move. Verified against the installed plugin: cursor on a note's final link,
-- call nav_link("next"), no movement. So ]o cannot be held down, and a note with many links costs
-- one keypress per link. nav_link is not called below because it returns no value to fall back
-- on; the scan is reimplemented so the fallback is the wrap.
--
-- No `;` mapping on purpose. `.` cannot repeat these -- it repeats the last *change*, and moving
-- the cursor is not one -- and `;` is core Vim's "repeat last f/t/F/T", which taking over
-- buffer-locally would break in every note. Wrapping is what makes holding ]o down work.
vim.keymap.set("n", "[o", function()
  nav_link_wrap "prev"
end, { buffer = true, desc = "Obsidian: Previous link" })

vim.keymap.set("n", "]o", function()
  nav_link_wrap "next"
end, { buffer = true, desc = "Obsidian: Next link" })
