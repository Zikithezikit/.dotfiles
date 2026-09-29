local PARA = { "Projects", "Areas", "Resources", "Archive", "Inbox" }

-- Folders offered by <leader>ow are read from the vault every time, so a folder or subfolder
-- created later shows up without editing this file. Directories that are infrastructure rather
-- than somewhere a note belongs are pruned, and never descended into.
local EXCLUDED_FOLDERS = {
  templates = true, -- source of the templates themselves
  assets = true, -- pasted images and attachments
}

local FOLDER_SCAN_DEPTH = 4 -- top level plus three levels of subfolders

---@param root string absolute vault root
---@param prefix string relative path of the directory being scanned ("" at the top)
---@param depth integer
---@param acc string[]
---@return string[]
local function scan_dirs(root, prefix, depth, acc)
  if depth > FOLDER_SCAN_DEPTH then
    return acc
  end
  local dir = prefix == "" and root or (root .. "/" .. prefix)
  for name, kind in vim.fs.dir(dir, { depth = 1 }) do
    if kind == "directory" and not name:match "^%." and not EXCLUDED_FOLDERS[name:lower()] then
      local rel = prefix == "" and name or (prefix .. "/" .. name)
      acc[#acc + 1] = rel
      scan_dirs(root, rel, depth + 1, acc)
    end
  end
  return acc
end

--- Every directory in the vault, as vault-relative paths like "Projects" or "Areas/journal".
--- Empty directories are included, which is the point: a folder just created has to be pickable.
---@param root obsidian.Path|string
---@return string[]
local function vault_folders(root)
  local folders = scan_dirs(tostring(root), "", 1, {})
  if #folders == 0 then
    -- empty or unreadable vault: fall back to the intended PARA layout
    folders = vim.deepcopy(PARA)
  end
  table.sort(folders)
  return folders
end

-- Obsidian Sync cannot upload these basenames; the Windows app can't open them either.
local RESERVED = {
  con = true,
  prn = true,
  aux = true,
  nul = true,
  com1 = true,
  com2 = true,
  com3 = true,
  com4 = true,
  com5 = true,
  com6 = true,
  com7 = true,
  com8 = true,
  com9 = true,
  lpt1 = true,
  lpt2 = true,
  lpt3 = true,
  lpt4 = true,
  lpt5 = true,
  lpt6 = true,
  lpt7 = true,
  lpt8 = true,
  lpt9 = true,
}

-- Two of obsidian.nvim's picker icons ship as empty strings (lua/obsidian/icons.lua), so notes
-- and PDFs render with no glyph at all. There is no `icons` config option in this fork — the only
-- lever is mutating the module tables, which `get_icon`/`get_path_icon` read at call time.
-- Both codepoints verified present in the installed VictorMono Nerd Font.
local ICON_FALLBACK = {
  md = "󰍔", -- nf-md-language_markdown
  markdown = "󰍔",
  qmd = "󰍔",
  pdf = "", -- nf-fa-file_pdf_o
}

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- latest tagged release; overrides this config's global `version = false`
  lazy = true,
  cmd = "Obsidian", -- so `:Obsidian today` works from any buffer, not just markdown
  ft = "markdown",
  -- Or restrict to the vault only:
  -- event = {
  --   "BufReadPre " .. vim.fn.expand "~" .. "/Documents/vault/**.md",
  --   "BufNewFile " .. vim.fn.expand "~" .. "/Documents/vault/**.md",
  -- },
  keys = {
    { "<leader>oo", "<cmd>Obsidian open<cr>", desc = "Obsidian: Open in app" },
    { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Obsidian: New note" },
    { "<leader>os", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: Quick switch" },
    { "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Obsidian: Today" },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: Backlinks" },
    { "<leader>oq", "<cmd>Obsidian search<cr>", desc = "Obsidian: Search" },
    { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Obsidian: Links in note" },
    { "<leader>ox", "<cmd>Obsidian extract_note<cr>", desc = "Obsidian: Extract note" },
    { "<leader>ou", "<cmd>Obsidian unique_note<cr>", desc = "Obsidian: Quick capture" },
    { "<leader>of", "<cmd>Obsidian follow_link vsplit<cr>", desc = "Obsidian: Follow link (split)" },
    { "<leader>oi", "<cmd>Obsidian insert_template<cr>", desc = "Obsidian: Insert template" },
    {
      "<leader>ch",
      "<cmd>Obsidian toggle_checkbox<cr>",
      desc = "Obsidian: Toggle checkbox (works on ranges too: :5,10Obsidian toggle_checkbox)",
    },
    {
      "<leader>oc",
      function()
        -- resolve_workspace_dir() tracks the configured workspace, so this follows
        -- opts.workspaces instead of hardcoding a second copy of the vault path.
        local root = tostring(require("obsidian.api").resolve_workspace_dir())
        vim.cmd.cd(root)
        vim.notify("cd " .. root, vim.log.levels.INFO, { title = "Obsidian" })
      end,
      desc = "Obsidian: cd to vault",
    },
    {
      "<leader>ow",
      function()
        local api = require "obsidian.api"
        local templates_dir = api.templates_dir()
        if not templates_dir then
          return vim.notify("Templates folder is not configured", vim.log.levels.ERROR)
        end

        -- Recursive, so templates can live in subfolders (daily/, para/, notes/, ...).
        -- Names come back relative to the templates dir and keep any subfolder prefix,
        -- which is exactly what resolve_template() expects. depth is a cap, not a setting:
        -- raise it if you ever nest templates more than 16 levels down.
        local names = {}
        for name, kind in vim.fs.dir(tostring(templates_dir), { depth = 16 }) do
          if kind == "file" and name:lower():match "%.md$" then
            names[#names + 1] = (name:gsub("%.md$", ""))
          end
        end
        if #names == 0 then
          return vim.notify("No templates found in " .. tostring(templates_dir), vim.log.levels.WARN)
        end
        table.sort(names)

        -- Everything below is callback-based, not `local x = vim.ui.select(...)`.
        -- Two reasons, both learned the hard way:
        --   1. snacks' vim.ui.select asserts `on_choice must be a function`, so the bare
        --      two-argument form is a hard error under it. The explicit three-argument
        --      form works under both snacks and dressing.
        --   2. the picker is asynchronous, so even where the two-argument form does not
        --      error (dressing), the return value is not the user's answer. Chaining the
        --      steps through callbacks is correct for either provider.
        -- Read from disk, so a folder added since this file was written is offered too.
        local folders = vault_folders(api.resolve_workspace_dir())
        vim.ui.select(names, { prompt = "Template" }, function(template)
          if not template then
            return
          end
          vim.ui.select(folders, { prompt = "Folder for this note" }, function(folder)
            if not folder then
              return
            end
            vim.ui.input({ prompt = "Title: " }, function(title)
              if not title or title == "" then
                return
              end

              -- `id` is what note_id_func actually receives (note.lua:366 calls
              -- generate_id(id, ...)); the @field title doc comment claims otherwise but
              -- the code does not. Slashes are flattened first because parse_as_path()
              -- runs before note_id_func and would make "a/b" a directory at the root.
              local note = require("obsidian.note").create {
                id = (title:gsub("/", "-")),
                aliases = { title },
                template = template,
                dir = folder,
              }
              note:write()
            end)
          end)
        end)
      end,
      desc = "Obsidian: New note from template",
    },
  },
  opts = {
    legacy_commands = false, -- recommended; will be removed in 4.0.0
    workspaces = {
      { name = "personal", path = "~/Documents/vault" },
    },

    new_notes_location = "current_dir",

    -- PARA: the folder you are in wins. Notes created at the vault root go to Inbox.
    --
    -- There is deliberately no vim.ui.select prompt here. note_path_func must return a path
    -- synchronously, but the configured picker (snacks) is asynchronous and its select()
    -- only answers through a callback -- so a prompt would either error out
    -- ("on_choice must be a function") or return nil before the user had chosen anything.
    -- Use <leader>ow when you want to pick the folder up front.
    note_path_func = function(spec)
      local api = require "obsidian.api"
      local root = api.resolve_workspace_dir()
      local at_root = root and spec.dir:resolve() == root:resolve()
      if at_root then
        local inbox = spec.dir / "Inbox"
        if inbox:is_dir() then
          return (inbox / (tostring(spec.id) .. ".md"))
        end
      end
      return (spec.dir / (tostring(spec.id) .. ".md"))
    end,

    -- title_id already strips Sync-illegal chars and dedupes with -2, -3, ...
    -- Only the Windows reserved basenames need guarding.
    note_id_func = function(title, path)
      local id = require("obsidian.builtin").title_id(title, path)
      return RESERVED[id:lower()] and (id .. "-note") or id
    end,

    link = {
      style = "wiki",
      format = "shortest",
      auto_update = true, -- follow external renames silently instead of prompting
    },

    -- Powers quick_switch, `[[query` completion, `[[##query` heading completion, and the
    -- link-suggestion inlay hints. Stored under stdpath("cache") as a JSON index; if it ever
    -- goes stale, `:Obsidian rebuild_cache`.
    cache = { enabled = true },

    daily_notes = {
      folder = "Areas/journal",
      -- date.format() routes any format containing a literal `%` to os.date (strftime) and
      -- anything else to Moment-style tokens, so the two lines below use different dialects.
      date_format = "YYYY-MM-DD", -- Moment-style
      alias_format = "%A %-d %B %Y", -- strftime
      default_tags = { "journal" },
      workdays_only = false, -- default is true, which makes :Obsidian today skip weekends
      template = "daily/daily-note", -- relative to templates.folder; subfolders work
    },

    templates = {
      folder = "templates",
      -- Built-ins already provided: date, time, title, id, path. Any `{{date:FORMAT}}` or
      -- `{{var:suffix}}` suffix overrides the format for that one call site.
      substitutions = {
        yesterday = function(_, suffix)
          return require("obsidian.date").format(os.time() - 86400, suffix or "YYYY-MM-DD")
        end,
        tomorrow = function(_, suffix)
          return require("obsidian.date").format(os.time() + 86400, suffix or "YYYY-MM-DD")
        end,
        now = function() return require("obsidian.date").format(os.time(), "YYYY-MM-DD HH:mm") end,
        week = function(_, suffix) return require("obsidian.date").format(os.time(), suffix or "YYYY-[W]WW") end,
        month = function(_, suffix) return require("obsidian.date").format(os.time(), suffix or "YYYY-MM") end,
        year = function() return require("obsidian.date").format(os.time(), "YYYY") end,
        quarter = function()
          local t = os.time()
          local date = require "obsidian.date"
          return date.format(t, "YYYY") .. "-Q" .. date.format(t, "Q")
        end,
      },
      -- Per-template routing, keyed on the template's filename stem, lowercased
      -- (note.lua:243 uses template_path.stem, so subfolder prefixes are NOT part of the key):
      --   templates.customizations = {
      --     meeting = { notes_subdir = "Projects" },
      --     ["big books"] = { notes_subdir = "Resources" },
      --   }
      -- Note it overrides note_id_func but keeps the global note_path_func above.
      customizations = {},
    },

    picker = {
      name = "snacks.picker", -- LazyVim's default here; telescope.nvim is also installed
    },

    -- There is no completion.blink / completion.nvim_cmp. Completion is served by the
    -- built-in obsidian-ls LSP server, surfaced through blink's default `lsp` source.
    completion = {
      min_chars = 2,
      match_case = false,
      create_new = true,
    },

    open = {
      use_advanced_uri = true, -- requires the obsidian-advanced-uri community plugin
    },

    attachments = { folder = "assets" },
    search = { sort_by = "modified", sort_reversed = true },

    -- `- [ ]` <-> `- [x]` in one keystroke, via <CR> (smart_action) or <leader>ch.
    --
    -- Both settings below deliberately depart from the plugin defaults:
    --
    -- * order defaults to { " ", "~", "!", ">", "x" }. Those symbols are inherited from
    --   epwalsh's original README, not from Obsidian: Obsidian core only knows `[ ]` and `[x]`
    --   (any character counts as complete), and `~ ! >` match nothing in the modern ecosystem.
    --   With the default order a single press on `- [ ]` lands on `[~]`, so reaching `[x]`
    --   takes four presses.
    -- * create_new defaults to true, and smart_action tests it with a bare `or`
    --   (actions.lua:191), so that branch is unconditionally true. Pressing <CR> on prose
    --   rewrites it into `- [ ] that prose`, and on an empty line injects `- [ ] `. Obsidian's
    --   app does this on <C-Enter>, which is not what most people mean by <CR> in an editor.
    --
    -- Dataview is the other argument: it treats a non-`x` status as checked=true but
    -- completed=false, so a task pressed into `[-]` still shows up in a "not completed" query
    -- while rendering as done in Obsidian. A two-state cycle cannot diverge.
    --
    -- Consequence to be aware of: a state that is not in `order` is reset to order[1]. Pressing
    -- on `- [-]` or `- [/]` (the Obsidian Tasks plugin convention) normalises it to `- [ ]`.
    checkbox = {
      enabled = true,
      create_new = false,
      order = { " ", "x" },
    },

    -- Teach Vim Obsidian's `%%comment%%` syntax so gc/comment operators work in the vault.
    comment = { enabled = true },

    footer = {
      enabled = true,
      separator = "", -- blank line instead of the default 80-dash rule
    },

    -- render-markdown.nvim is installed (LazyVim's lang.markdown extra), so obsidian.nvim skips
    -- its own extmark UI regardless (workspace.lua:172). Being explicit also keeps the two
    -- renderers out of each other's :checkhealth. Obsidian's UI module is slated for removal
    -- once Neovim gains native presentation mode.
    ui = { enable = false },

    callbacks = {
      post_setup = function()
        local icons = require "obsidian.icons"
        for ext, glyph in pairs(ICON_FALLBACK) do
          icons.by_extension[ext] = glyph
        end
        icons.kinds.note = ICON_FALLBACK.md
        icons.kinds.pdf = ICON_FALLBACK.pdf
      end,
    },
  },
}