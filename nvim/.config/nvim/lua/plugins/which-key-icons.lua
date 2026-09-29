-- Icons for the LazyVim leader menu.
--
-- which-key v3 has icons on by default: 41 built-in rules already cover LazyVim's bundled
-- plugins, and `opts.icons.rules` is PREPENDED to those rather than replacing them, so this
-- file only needs to cover what they miss. `pattern` matches the keymap's *description*
-- (lowercased, raw Lua pattern) -- not the plugin name -- which is why the rules below are
-- word-anchored with %f[%a] to avoid matching inside unrelated words.
--
-- Icons must go through which-key's `spec`, not through a lazy.nvim `keys` entry.
-- `vim.keymap.set` rejects unknown opts, so `icon = "..."` on a keymap is a runtime error:
--     E5108: vim/keymap.lua:0: invalid key: icon
-- lazy.nvim forwards everything except mode/id/ft/rhs/lhs straight to vim.keymap.set, so it
-- blows up the moment the mapping is materialised. Spec entries with no `rhs` are nodes, not
-- mappings, so they attach an icon to the existing obsidian keymap instead of adding one.
--
-- Requires a Neovim restart (not :Lazy reload) -- which-key defers its real work to VimEnter.
--
-- Every glyph below was looked up by name in the installed VictorMono Nerd Font with
-- fontTools; the name is in the comment so the codepoint is traceable.

return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        -- <leader>o is ours (LazyVim does not define it), so a bare group is safe here.
        {
          "<leader>o",
          group = "obsidian",
          icon = { icon = "󰍔", color = "purple" }, -- md-language_markdown
        },
        { "<leader>oo", icon = { icon = "󰌧", color = "blue" } }, -- md-launch
        { "<leader>on", icon = { icon = "󰎜", color = "green" } }, -- md-note_plus
        { "<leader>os", icon = { icon = "󰍉", color = "cyan" } }, -- md-magnify
        { "<leader>ot", icon = { icon = "󰃶", color = "orange" } }, -- md-calendar_today
        { "<leader>ob", icon = { icon = "󰌹", color = "yellow" } }, -- md-link_variant
        { "<leader>oq", icon = { icon = "󱉶", color = "cyan" } }, -- md-magnify_scan
        { "<leader>ol", icon = { icon = "󰌷", color = "blue" } }, -- md-link
        { "<leader>ox", icon = { icon = "󰸧", color = "red" } }, -- md-content_save_move
        { "<leader>ou", icon = { icon = "󱐋", color = "orange" } }, -- md-lightning_bolt
        { "<leader>of", icon = { icon = "󰜴NTA", color = "green" } }, -- md-arrow_right_bold
        { "<leader>oi", icon = { icon = "󰈚", color = "purple" } }, -- md-text_box
        { "<leader>oc", icon = { icon = "󰉋", color = "yellow" } }, -- md-folder
        { "<leader>ow", icon = { icon = "󰪶", color = "green" } }, -- md-file_cabinet
        { "<leader>ch", icon = { icon = "󰄲", color = "green" } }, -- md-checkbox_marked
      },
      icons = {
        rules = {
          -- `pattern` is only valid HERE, in icons.rules (an IconRule). Putting one in `spec`
          -- fails validation: "Invalid field `pattern`" from mappings.lua:167, because a spec
          -- entry is a Mapping and that has no such field.
          --
          -- pattern matches the *description* (lowercased, raw Lua pattern) -- not the plugin
          -- name -- so keep it word-anchored or "git" also hits "legitimate". These run before
          -- which-key's 41 built-ins, which stay reachable as a fallback.
          --
          -- The obsidian/template/backlink patterns are a safety net for any obsidian keymap
          -- that is not listed in the spec above; today every one of them is.
          { pattern = "%f[%a]obsidian", icon = { icon = "󰍔", color = "purple" } },
          { pattern = "%f[%a]template", icon = { icon = "󰈚", color = "purple" } },
          { pattern = "%f[%a]backlink", icon = { icon = "󰌹", color = "yellow" } },

          -- provider form: resolved through mini.icons, keeping its own highlight.
          -- mini.icons is what LazyVim 16 ships, and which-key tries it first in its provider
          -- list, so no extra dependency is needed.
          --
          -- Both names verified to resolve (U+F02A2 / U+F0320). Note that a name mini.icons
          -- does not know returns nil and the rule is skipped silently -- an "lsp" filetype
          -- rule was tried and removed for exactly that reason.
          { pattern = "%f[%a]git", cat = "filetype", name = "git", color = "orange" },
          { pattern = "%f[%a]python", cat = "filetype", name = "python", color = "yellow" },
        },
      },
    },
  },
}