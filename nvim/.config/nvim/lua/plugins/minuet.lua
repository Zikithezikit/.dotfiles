-- Ghost-text completion from Claude Haiku, through the logged-in Claude Code CLI (lua/minuet/backends/claude_code.lua)
-- so the Claude subscription is enough. Off if the `claude` CLI is missing.
local has_claude = vim.fn.executable("claude") == 1

-- Global on/off for the automatic ghost text (<leader>ah, :HaikuGhost), remembered across sessions: the marker
-- file exists = off. Manual requests (<C-Space>, <A-]>) still work while it is off.
-- The AI in the <C-Space> menu has its own switch (<A-a>, <leader>am), same marker-file scheme.
local off_file = vim.fn.stdpath("state") .. "/haiku_ghost_text_off"
vim.g.haiku_ghost_text = vim.uv.fs_stat(off_file) == nil

local menu_off_file = vim.fn.stdpath("state") .. "/haiku_menu_off"
vim.g.haiku_menu = vim.uv.fs_stat(menu_off_file) == nil

local function set_menu(on)
  vim.g.haiku_menu = on
  if on then
    os.remove(menu_off_file)
  else
    io.open(menu_off_file, "w"):close()
  end
  vim.notify("Haiku in the completion menu " .. (on and "enabled" or "disabled"), vim.log.levels.INFO)
  local ok, cmp = pcall(require, "blink.cmp")
  if ok and cmp.is_menu_visible() then -- reopen so the change applies to the menu that is showing
    cmp.hide()
    vim.schedule(cmp.show)
  end
end

local function set_ghost(on)
  vim.g.haiku_ghost_text = on
  if on then
    os.remove(off_file)
  else
    io.open(off_file, "w"):close()
    pcall(function() require("minuet.virtualtext").action.dismiss() end)
  end
  vim.notify("Haiku ghost text " .. (on and "enabled" or "disabled"), vim.log.levels.INFO)
end

return {
  "milanglacier/minuet-ai.nvim",
  enabled = has_claude,
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    provider = "claude_code",
    provider_options = {
      claude_code = {
        model = "haiku", -- alias resolves to the latest Haiku
        timeout_ms = 10000, -- a request running longer than this is killed and ignored
        max_per_minute = 15, -- hard cap on requests, whatever the typing pattern
        max_failures = 3, -- this many failures in a row pause requests for pause_ms
        pause_ms = 60000,
        -- repo context from the language server (see claude_code.lua); lsp_context = false turns it off
        lsp_context = true,
        lsp_timeout_ms = 300, -- the language server gets this long, then the request goes out without its context
        lsp_max_candidates = 12, -- symbols near the cursor that are looked up
        lsp_max_chars = 1500, -- total size of the context block
        lsp_max_chars_each = 400,
      },
    },
    debounce = 700, -- ms of no typing before an automatic request
    throttle = 3000, -- ms minimum gap between automatic requests
    -- all must be true for an automatic request: switched on, a real file, not a huge one
    enable_predicates = {
      function() return vim.g.haiku_ghost_text end,
      function() return vim.bo.buftype == "" end,
      function() return vim.api.nvim_buf_line_count(0) < 5000 end,
    },
    n_completions = 1, -- one suggestion per request keeps ghost text fast
    context_window = 8000, -- characters around the cursor
    -- ghost text: shows while typing in these filetypes, <C-Space> (blink, below) still works everywhere
    virtualtext = {
      auto_trigger_ft = {
        "c", "cpp", "python", "rust", "go", "lua", "sh", "fish", "make", "cmake",
        "typescript", "typescriptreact", "javascript", "javascriptreact", "html", "htmldjango", "css", "sql",
        "yaml", "toml", "json", "jsonc",
      },
      keymap = {
        -- <Tab> also accepts ghost text through blink.lua when no completion item is selected
        accept = "<A-y>",
        accept_line = "<A-l>",
        next = "<A-]>",
        prev = "<A-[>",
        dismiss = "<A-e>",
      },
      show_on_completion_menu = false,
    },
    blink = { enable_auto_complete = false }, -- the blink source only runs on <C-Space>
  },
  config = function(_, opts)
    require("minuet").setup(opts)
    -- <A-a> in insert mode flips the AI on/off for the <C-Space> menu; an open menu is reopened so it takes effect
    vim.keymap.set("i", "<A-a>", function()
      set_menu(not vim.g.haiku_menu)
    end, { desc = "Toggle Haiku in the completion menu" })
    vim.api.nvim_create_user_command("HaikuGhost", function(a)
      set_ghost(a.args == "on" or (a.args ~= "off" and not vim.g.haiku_ghost_text))
    end, { nargs = "?", complete = function() return { "on", "off", "toggle" } end, desc = "Haiku ghost text on/off/toggle" })
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        Snacks.toggle({
          name = "Haiku ghost text",
          get = function() return vim.g.haiku_ghost_text end,
          set = set_ghost,
        }):map("<leader>ah")
        Snacks.toggle({
          name = "Haiku in completion menu",
          get = function() return vim.g.haiku_menu end,
          set = set_menu,
        }):map("<leader>am")
      end,
    })
  end,
}
