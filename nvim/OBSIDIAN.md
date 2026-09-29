# Memo: nvim second brain via obsidian.nvim

Status: **plan, not yet implemented.** Written 2026-09-29.

## Decisions

| Question | Answer | Consequence |
| --- | --- | --- |
| Vault location | `~/Documents/vault` | Single workspace, no `notes_subdir` |
| Structure | PARA | Folder-routing `note_path_func`, PARA `select` prompt at root |
| Completion | Switch to nvim-cmp | Delete `blink.lua`, import LazyVim's `coding.nvim-cmp` extra |
| Sync | Desktop app + mobile | **Obsidian Sync naming rules become a hard constraint** |

## Findings that shape the work

**1. `epwalsh/obsidian.nvim` has no release covering its own docs.**
Latest tag is `v3.9.0` (Jul 2024) and it uses a *different* config API (`mappings` as bare
functions plus a separate `mappings_opts`). The README on `main` documents a rewritten API
(table-form `mappings`, `Note` objects, `:ObsidianCheck`). Install `branch = "main"`, **not**
`version = "*"`. 196 open issues, last commit Apr 2026 (`726b60c`).

**2. LazyVim 16.0.1 dropped its bundled completion engine.**
Verified against the install at `~/.local/share/nvim/lazy/LazyVim` (commit `99970099`, v16.0.1).
Core `coding.lua` is now just mini.pairs / ts-comments / mini.ai / lazydev — no
`hrsh7th/nvim-cmp`. Switching to nvim-cmp therefore means *importing the extra*, not just
deleting blink:

```lua
{ import = "lazyvim.plugins.extras.coding.nvim-cmp" }
```

That extra pulls in `nvim-cmp`, `cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`, and disables
`blink.cmp` itself. obsidian.nvim then self-registers its `obsidian`, `obsidian_new`, and
`obsidian_tags` sources on vault markdown buffers — no manual wiring.

**3. The picker is the constraint for search.**
obsidian.nvim supports only telescope / fzf-lua / mini.pick. **No snacks.picker.** Telescope is
present via the `editor.telescope` extra recorded in `lazyvim.json`, so set
`picker.name = "telescope.nvim"` explicitly — otherwise the plugin walks a pcall chain probing
for `mini.pick`, which LazyVim 16 does not install.

**4. Image paste will hard-error as things stand.**
`img_paste.lua` branches on `os.getenv("XDG_SESSION_TYPE")`, which is currently **empty** despite
running Wayland. With the var unset, `check_cmd` is `nil` and `io.popen(nil)` errors. Needs
`wl-clipboard` installed *and* the var exported.

**5. No sqlite3 is needed.**
The graph command is gone in the rewrite. Nothing in the new plugin shells out to sqlite3.

## Phase 0 — System prerequisites

```bash
sudo pacman -S wl-clipboard          # wl-paste, for :ObsidianPasteImg
```

Add to `fish/.config/fish/config.fish`:

```fish
set -gx XDG_SESSION_TYPE wayland
```

Do **not** work around this with `XDG_SESSION_TYPE x11` even though `xclip` is installed. It
works via XWayland but handles non-PNG clipboard data incorrectly.

> Fixing this is worth doing independently of Obsidian — other tools branch on the same variable.

## Phase 1 — Vault scaffold

```bash
mkdir -p ~/Documents/vault/{Projects,Areas,Resources,Archive,Inbox,assets}
mkdir -p ~/Documents/vault/templates
cd ~/Documents/vault && git init
```

`~/Documents/vault/.gitignore` — Obsidian Sync and git disagree about dotfolders, so pin it:

```gitignore
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache/
.trash/
```

`~/Documents/vault/.obsidian/app.json` — makes the desktop app write links the same way
obsidian.nvim does, so the two don't fight over format:

```json
{ "alwaysUpdateLinks": true, "newLinkFormat": "shortest", "attachmentFolderPath": "assets" }
```

### Sync-safe naming (the constraint that shapes Phase 3)

Obsidian Sync rejects `\ / : * ? " < > |`, control characters, leading/trailing spaces or
periods, Windows reserved basenames, and dotfiles. Since mobile is in scope, **note IDs must be
`[a-z0-9_-]` only.** Human-readable titles are preserved in frontmatter `aliases:` instead —
that split is the whole point.

## Phase 2 — Swap blink.cmp for nvim-cmp

Delete `nvim/.config/nvim/lua/plugins/blink.lua`, then in `nvim/.config/nvim/lua/config/lazy.lua`:

```lua
    { import = "lazyvim.plugins.extras.coding.nvim-cmp" },
```

Side effect to be aware of: the current `blink.lua` maps both `<Tab>` and `<CR>` to
accept+fallback. The LazyVim nvim-cmp extra maps `<CR>` to `LazyVim.cmp.confirm` and `<tab>` to
snippet-forward. Completion muscle memory changes slightly, in code too — not just the vault.

## Phase 3 — The obsidian.nvim spec

New file: `nvim/.config/nvim/lua/plugins/obsidian.lua`

```lua
local PARA = { "Projects", "Areas", "Resources", "Archive", "Inbox" }

-- Obsidian Sync rejects these basenames outright, and the desktop app can't open them.
local RESERVED = {
  con = true, prn = true, aux = true, nul = true,
  com1 = true, com2 = true, com3 = true, com4 = true, com5 = true,
  com6 = true, com7 = true, com8 = true, com9 = true,
  lpt1 = true, lpt2 = true, lpt3 = true, lpt4 = true, lpt5 = true,
  lpt6 = true, lpt7 = true, lpt8 = true, lpt9 = true,
}

return {
  "epwalsh/obsidian.nvim",
  branch = "main", -- v3.9.0 is the last release and has a different API than the docs
  commit = "726b60c89f4bafef267a714ea1faa1335bdd414a",
  lazy = true,
  event = {
    "BufReadPre " .. vim.fn.expand "~" .. "/Documents/vault/*.md",
    "BufNewFile " .. vim.fn.expand "~" .. "/Documents/vault/*.md",
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: Open in app" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: New note" },
    { "<leader>os", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: Quick switch" },
    { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian: Today" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: Backlinks" },
    { "<leader>osr", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: Search" },
    { "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Obsidian: Links in note" },
    { "<leader>ox", "<cmd>ObsidianExtractNote<cr>", desc = "Obsidian: Extract to new note" },
  },
  opts = {
    workspaces = { { name = "personal", path = "~/Documents/vault" } },

    -- PARA: the folder you are in wins. Starting at the vault root prompts.
    new_notes_location = "current_dir",
    note_path_func = function(spec)
      local obsidian = require "obsidian"
      local client = obsidian.get_client()
      local root = client and client.workspace and client.workspace.root
      local at_root = root and (spec.dir == root or spec.dir:resolve() == root:resolve())
      if at_root then
        local pick = vim.ui.select(PARA, { prompt = "PARA folder" }) or "Inbox"
        return spec.dir / pick / (tostring(spec.id) .. ".md")
      end
      return spec.dir / (tostring(spec.id) .. ".md")
    end,

    -- Sync-safe slug. The readable title lives in frontmatter aliases instead.
    note_id_func = function(title)
      if not title or title == "" then
        return tostring(os.time())
      end
      local slug = title:lower():gsub("[^%w_-]+", "-"):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
      if slug == "" then
        return tostring(os.time())
      end
      if RESERVED[slug] then
        slug = slug .. "-note"
      end
      if #slug > 80 then
        slug = slug:sub(1, 80):gsub("%-$", "")
      end
      return slug
    end,

    daily_notes = {
      folder = "Areas/journal",
      date_format = "%Y-%m-%d",
      alias_format = "%A %-d %B %Y",
      default_tags = { "journal" },
      template = "daily",
    },

    templates = {
      folder = "templates",
      substitutions = {
        yesterday = function()
          return os.date("%Y-%m-%d", os.time() - 86400)
        end,
      },
    },

    preferred_link_style = "wiki",
    picker = { name = "telescope.nvim" },
    use_advanced_uri = true, -- requires the obsidian-advanced-uri community plugin
    open_app_foreground = true,
    attachments = { img_folder = "assets" },
    sort_by = "modified",
    sort_reversed = true,

    ui = {
      -- dracula-native highlight tweaks; drop the block for upstream defaults
      hl_groups = {
        ObsidianRefText = { underline = true, fg = "#bd93f9" },
        ObsidianTag = { italic = true, fg = "#8be9fd" },
        ObsidianTodo = { bold = true, fg = "#ffb86c" },
        ObsidianDone = { bold = true, fg = "#50fa7b" },
        ObsidianBullet = { fg = "#8be9fd" },
      },
    },
  },
}
```

**Why `commit =` is pinned.** `lazy.lua` sets `version = false` globally, so LazyVim tracks the
tip of `main` — and that branch has 196 open issues and no release cut. Pinning means a breaking
upstream commit lands on `:Lazy update`, not mid-writing-session. Drop the `commit` line once
stability is confirmed.

## Phase 4 — Autocmds

obsidian.nvim's extmarks need `conceallevel` set locally. `lua/config/autocmds.lua` already has
content, so **append** rather than replace:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    if vim.api.nvim_buf_get_name(ev.buf):find(vim.fn.expand "~" .. "/Documents/vault", 1, true) == 1 then
      vim.opt_local.conceallevel = 1
    end
  end,
})
```

**Leave `render-markdown.nvim` alone.** LazyVim's markdown extra already sets
`checkbox.enabled = false` specifically so obsidian.nvim's checkbox glyphs aren't doubled. Since
this config uses `preferred_link_style = "wiki"`, obsidian.nvim writes `[[refs]]` while
render-markdown only touches `[md](links)` — different syntax, no overlap. Only if doubled icons
show up on markdown links should `link = { enabled = false }` be set for vault buffers.

## Phase 5 — Mobile + desktop app

1. Install **obsidian-advanced-uri** in the vault's community plugins (required by
   `use_advanced_uri = true`).
2. Open the vault in the desktop app, log into Obsidian Sync with end-to-end encryption.
3. Open the same vault in the mobile app via Sync.

`:ObsidianOpen` / `<leader>oo` is the payoff: jump from a terminal-embedded nvim into the app GUI
at the current note.

## Phase 6 — Verification

```vim
:Lazy sync                     " install obsidian.nvim + nvim-cmp sources
:Obsidian today               " creates Areas/journal/2026-09-29.md from the template
:ObsidianNew "Reading: Dune"  " expect reading-dune.md, readable title in aliases
:ObsidianCheck                " scans every note, reports errors + timing
:ObsidianQuickSwitch          " telescope over the vault
:ObsidianBacklinks            " after creating a link
```

Then test the sync constraint specifically: confirm `:ObsidianPasteImg` works (this is the
Phase 0 `wl-clipboard` gate), and that a note titled `con` becomes `con-note.md` rather than
`con.md`.

## Risks

- **blink → nvim-cmp is global, not vault-scoped.** It changes completion in the Python work
  too. That's the cost of the only supported path. A markdown-scoped blink source is ~40 lines
  wrapping `cmp_obsidian.complete()` if a revert is ever wanted (note: obsidian.nvim PR #817 for
  native blink support was closed unmerged).
- **`main` is unreleased.** Treat the first fortnight as probation. `git checkout` inside the
  plugin dir is the escape hatch.
- **`XDG_SESSION_TYPE` unset is a latent bug** independent of Obsidian.

## Order of work

Phase 0 → 1 → `:Lazy sync` → 2 → 3 → 4 → 5.

The blink swap goes *before* the obsidian spec so only one variable is in play at a time.
