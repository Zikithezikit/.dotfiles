-- LazyVim runs mason-lspconfig with automatic_enable, so EVERY server ever installed in Mason starts on
-- every buffer unless it is listed below with enabled = false. That was the source of the crashing
-- ltex-ls (Java), ast-grep complaining about missing sgconfig, and jedi duplicating basedpyright.
local off = { enabled = false }
local watching = {} -- project roots whose compile_commands.json we are waiting for

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jedi_language_server = off, -- basedpyright covers it
        ltex = off,
        ltex_plus = off,
        ast_grep = off, -- needs an sgconfig.yml per project, errors everywhere else
        esbonio = off, -- Sphinx/rst only
        autotools_ls = off,
        djls = off, -- duplicates djlsp (django.lua)

        basedpyright = {
          -- manage.py: Django projects often have no pyproject.toml, which left the server rootless
          root_markers = { "pyproject.toml", "manage.py", "setup.py", "setup.cfg", "requirements.txt", "pyrightconfig.json", ".git" },
          -- pyright never discovers a project .venv on its own: point it at one (or the active $VIRTUAL_ENV)
          before_init = function(_, config)
            local venv = vim.env.VIRTUAL_ENV or (config.root_dir and config.root_dir .. "/.venv")
            local py = venv and venv .. "/bin/python"
            if py and vim.uv.fs_stat(py) then
              config.settings = vim.tbl_deep_extend("force", config.settings or {}, { python = { pythonPath = py } })
            end
          end,
          settings = {
            basedpyright = {
              disableOrganizeImports = true, -- ruff does it
              analysis = {
                -- default is "recommended": flags every untyped param/return and duplicates ruff
                typeCheckingMode = "standard",
                diagnosticMode = "openFilesOnly",
                autoImportCompletions = true,
                inlayHints = { callArgumentNames = true },
                diagnosticSeverityOverrides = {
                  reportUnusedImport = "none", -- ruff reports these
                  reportUnusedVariable = "none",
                  reportMissingTypeStubs = "none",
                  -- Django: `Model.objects` etc. are runtime-added; add django-stubs to make this exact
                  reportAttributeAccessIssue = "warning",
                },
              },
            },
          },
        },

        ruff = {
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false -- basedpyright hover is better
            client.server_capabilities.documentSymbolProvider = false
          end,
        },

        clangd = {
          -- groups are tried in order: a compile database wins, then the repo root, then any build file
          -- (LazyVim's flat list had no CMakeLists.txt, leaving CMake projects outside git rootless)
          root_markers = {
            { "compile_commands.json", "compile_flags.txt" },
            { ".git" },
            { "CMakeLists.txt", "Makefile", "meson.build", "build.ninja", "configure.ac" },
          },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--all-scopes-completion",
            "--pch-storage=memory",
            "-j=4",
            -- let clangd ask the real compiler for its system include paths (fixes bogus 'stdio.h not found')
            "--query-driver=/usr/bin/**/*,/usr/local/bin/**/*,/usr/lib/**/*",
          },
          on_attach = function(client)
            local root = client.root_dir
            if not root or watching[root] then
              return
            end
            local function has_db()
              return vim.fn.filereadable(root .. "/compile_commands.json") == 1 or vim.fn.filereadable(root .. "/compile_flags.txt") == 1
            end
            if has_db() then
              return
            end
            vim.notify("clangd: no compile_commands.json in " .. root .. " (include errors are expected). Press <leader>cB (Make) or <leader>mg (CMake) to generate it.", vim.log.levels.WARN)
            -- clangd only reads the compile database at startup (LSP file watching is off), so restart it once it appears
            local w = vim.uv.new_fs_event()
            watching[root] = w
            w:start(root, {}, vim.schedule_wrap(function()
              -- one directory write fires several events: act on the first only
              if watching[root] == w and has_db() then
                w:close()
                watching[root] = nil
                vim.cmd("lsp restart clangd")
              end
            end))
          end,
          -- A Makefile-only project has no compile_commands.json: <leader>cB generates one with bear.
          keys = {
            {
              "<leader>cB",
              function()
                local root = vim.fs.root(0, { "Makefile", "CMakeLists.txt", ".git" }) or vim.fn.getcwd()
                local cmd = vim.fn.filereadable(root .. "/CMakeLists.txt") == 1
                    and "cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ln -sf build/compile_commands.json ."
                  or "bear -- make -B"
                Snacks.terminal(cmd, { cwd = root })
              end,
              desc = "Generate compile_commands.json (bear/cmake)",
            },
          },
        },
      },
    },
  },

  -- Formatters/fixers run on save through conform (LSP formatting stays as the fallback)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      },
    },
  },
}
