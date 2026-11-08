return {
  "milanglacier/minuet-ai.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "InsertEnter",
  opts = {
    provider = "gemini",
    provider_options = {
      gemini = {
        model = "gemini-3.5-flash-lite", -- API key comes from $GEMINI_API_KEY
        optional = {
          generationConfig = { maxOutputTokens = 256 },
        },
      },
    },
    virtualtext = {
      auto_trigger_ft = { "*" },
      auto_trigger_ignore_ft = { "gitcommit", "gitrebase" },
      show_on_completion_menu = true, -- blink's menu is almost always open while typing
      keymap = {
        accept = "<M-l>", -- <Tab> belongs to blink.cmp
        accept_line = "<M-L>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<M-e>",
      },
    },
  },
}
