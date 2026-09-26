return {
  "Davidyz/inlayhint-filler.nvim",
  keys = {
    {
      "<Leader>I",
      function()
        require("inlayhint-filler").fill()
      end,
      desc = "Insert inlay hint under cursor",
      mode = { "n", "v" },
    },
  },
  opts = {
    force = false,
    eager = false,
    verbose = false,
  },
}
