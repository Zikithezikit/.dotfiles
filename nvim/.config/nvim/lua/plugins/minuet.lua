-- Gemini completion needs $GEMINI_API_KEY; without it the plugin errors on every startup, so stay off.
local has_key = (vim.env.GEMINI_API_KEY or "") ~= ""

return {
  "milanglacier/minuet-ai.nvim",
  enabled = has_key,
  dependencies = { "nvim-lua/plenary.nvim" },
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
    blink = { enable_auto_complete = false }, -- only runs on <C-Space>
  },
}
