-- lazyvim.plugins.extras.lang.cmake gives neocmakelsp, cmakelint, cmake-format and loads cmake-tools when
-- cwd has a CMakeLists.txt, but defines no keys and defaults the debugger to cppdbg (not installed here).
return {
  {
    "Civitasv/cmake-tools.nvim",
    cmd = { "CMakeGenerate", "CMakeBuild", "CMakeRun", "CMakeDebug", "CMakeSelectBuildType" },
    keys = {
      { "<leader>mg", "<cmd>CMakeGenerate<cr>", desc = "CMake generate" },
      { "<leader>mb", "<cmd>CMakeBuild<cr>", desc = "CMake build" },
      { "<leader>mr", "<cmd>CMakeRun<cr>", desc = "CMake run target" },
      { "<leader>md", "<cmd>CMakeDebug<cr>", desc = "CMake debug target" },
      { "<leader>mt", "<cmd>CMakeRunTest<cr>", desc = "CMake run ctest" },
      { "<leader>mc", "<cmd>CMakeClean<cr>", desc = "CMake clean" },
      { "<leader>ms", "<cmd>CMakeSelectBuildType<cr>", desc = "CMake build type (Debug/Release)" },
      { "<leader>mB", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake build target" },
      { "<leader>mT", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "CMake launch target" },
      { "<leader>mp", "<cmd>CMakeSelectConfigurePreset<cr>", desc = "CMake configure preset" },
    },
    opts = {
      cmake_build_directory = "build/${variant:buildType}",
      -- clangd reads compile_commands.json from the project root: link the generated one there
      cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
      cmake_soft_link_compile_commands = true,
      cmake_dap_configuration = { name = "cpp", type = "codelldb", request = "launch", stopOnEntry = false, runInTerminal = true, console = "integratedTerminal" },
    },
  },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { cmake = { "cmake_format" } } } },
  {
    "folke/which-key.nvim",
    -- Icon goes through spec nodes, not icons.rules (a second icons.rules would clobber which-key-icons.lua).
    -- 0xe794 = nf-dev-cmake (the CMake logo); nr2char keeps the glyph from being lost in the source file.
    opts = function(_, opts)
      local icon = { icon = vim.fn.nr2char(0xe794), color = "azure" }
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>m", group = "cmake", icon = icon })
      for _, key in ipairs({ "g", "b", "r", "d", "t", "c", "s", "B", "T", "p" }) do
        table.insert(opts.spec, { "<leader>m" .. key, icon = icon })
      end
    end,
  },
}
