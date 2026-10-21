-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- VSCode-style: in visual mode, typing a bracket/quote wraps the selection
local function wrap_selection(open, close)
  return function()
    local mode = vim.fn.mode()
    local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
    if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
      s, e = e, s
    end
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    local buf = vim.api.nvim_get_current_buf()
    local srow, scol, erow, ecol = s[2] - 1, s[3] - 1, e[2] - 1, e[3]
    if mode == "V" then
      scol = 0
      ecol = #vim.api.nvim_buf_get_lines(buf, erow, erow + 1, true)[1]
    else
      -- include the whole last (possibly multibyte) character
      local line = vim.api.nvim_buf_get_lines(buf, erow, erow + 1, true)[1]
      local ch = vim.fn.strcharpart(line:sub(ecol), 0, 1)
      ecol = math.min(#line, ecol - 1 + #ch)
    end
    vim.api.nvim_buf_set_text(buf, erow, ecol, erow, ecol, { close })
    vim.api.nvim_buf_set_text(buf, srow, scol, srow, scol, { open })
    vim.api.nvim_win_set_cursor(0, { srow + 1, scol + #open })
  end
end

for open, close in pairs({
  ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["`"] = "`",
}) do
  vim.keymap.set("x", open, wrap_selection(open, close), { desc = "Wrap selection with " .. open .. close })
  if open ~= close then
    vim.keymap.set("x", close, wrap_selection(open, close), { desc = "Wrap selection with " .. open .. close })
  end
end
