-- LSP Configuration with Mason and Neovim 0.12+ APIs
-- Complete setup for Python development

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Mason for LSP server management
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",

      -- Additional capabilities
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Note: Diagnostics are provided by pylsp with python-lsp-ruff plugin
      -- Ruff LSP is used for code actions (fix all, organize imports) and formatting only

      -- Setup Mason first
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      ---@type table<string, vim.lsp.ClientConfig>
      local lsp_servers = {}

      --- Register a server and record it so the enable/toggle loop below picks it up.
      ---
      --- Deliberately does NOT default `cmd`. vim.lsp.config() merges on top of the
      --- `lsp/<name>.lua` defaults nvim-lspconfig puts on the runtimepath, and those
      --- already carry the right command. LSP *names* are not binary names —
      --- lua_ls is `lua-language-server`, bashls is `bash-language-server start`,
      --- basedpyright is `basedpyright-langserver --stdio` (the bare `basedpyright`
      --- binary is the CLI type checker, which spawns fine and then never speaks
      --- LSP). Defaulting cmd to server_name silently broke all three.
      ---@param server_name string Server name displayed in the UI config
      ---@param client_config vim.lsp.Config Custom server configuration to register
      local function register_server(server_name, client_config)
        lsp_servers[server_name] = client_config
        vim.lsp.config(server_name, client_config)
      end

      -- Get capabilities from cmp_nvim_lsp first
      -- local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- Function to detect Python interpreter
      local function get_python_path()
        -- Check for Poetry venv
        local poetry_venv = vim.fn.trim(vim.fn.system("poetry env info -p 2>/dev/null"))
        if vim.v.shell_error == 0 and poetry_venv ~= "" then
          return poetry_venv .. "/bin/python"
        end

        -- Check for standard venv locations
        local venv_paths = {
          vim.fn.getcwd() .. "/.venv/bin/python",
          vim.fn.getcwd() .. "/venv/bin/python",
          vim.fn.expand("~/.virtualenvs/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. "/bin/python"),
        }

        for _, path in ipairs(venv_paths) do
          if vim.fn.executable(path) == 1 then
            return path
          end
        end

        -- Fallback to system Python. `exepath()` returns an empty string when
        -- missing, and empty strings are truthy in Lua.
        local python3 = vim.fn.exepath("python3")
        if python3 ~= "" then
          return python3
        end
        local python = vim.fn.exepath("python")
        if python ~= "" then
          return python
        end
        return "python"
      end

      -- LspAttach autocmd for on_attach logic (Neovim 0.12+ pattern)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        ---@param args vim.api.keyset.create_autocmd.callback_args
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf

          if not client then
            return
          end

          local opts = { buffer = bufnr, silent = true }

          -- LSP keybindings
          vim.keymap.set(
            "n",
            "gd",
            vim.lsp.buf.definition,
            vim.tbl_extend("force", opts, { desc = "Go to definition" })
          )

          vim.keymap.set("n", "gD", function()
            -- Fall back to definition when no attached server advertises
            -- `declarationProvider` (true for lua_ls, pyright, ruff, etc.).
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            for _, c in ipairs(clients) do
              if c.server_capabilities and c.server_capabilities.declarationProvider then
                return vim.lsp.buf.declaration()
              end
            end
            vim.lsp.buf.definition()
          end, vim.tbl_extend("force", opts, { desc = "Go to declaration (falls back to definition)" }))
          vim.keymap.set(
            "n",
            "gi",
            vim.lsp.buf.implementation,
            vim.tbl_extend("force", opts, { desc = "Go to implementation" })
          )

          vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Show references" }))

          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))

          vim.keymap.set(
            "n",
            "<C-k>",
            vim.lsp.buf.signature_help,
            vim.tbl_extend("force", opts, { desc = "Signature help" })
          )

          vim.keymap.set(
            "n",
            "<leader>rn",
            vim.lsp.buf.rename,
            vim.tbl_extend("force", opts, { desc = "Rename symbol" })
          )

          vim.keymap.set(
            { "n", "v" },
            "<leader>ca",
            vim.lsp.buf.code_action,
            vim.tbl_extend("force", opts, { desc = "Code action" })
          )

          -- Python-specific code actions (work in any file, but most useful for Python)
          -- Fix all auto-fixable issues (Ruff)
          vim.keymap.set("n", "<leader>cf", function()
            vim.lsp.buf.code_action({
              context = { only = { "source.fixAll" }, diagnostics = {} },
              apply = true,
            })
          end, vim.tbl_extend("force", opts, { desc = "Fix all (Ruff)" }))

          -- Organize imports
          vim.keymap.set("n", "<leader>co", function()
            vim.lsp.buf.code_action({
              context = { only = { "source.organizeImports" }, diagnostics = {} },
              apply = true,
            })
          end, vim.tbl_extend("force", opts, { desc = "Organize imports" }))

          -- Refactoring actions (extract, inline, etc.)
          vim.keymap.set({ "n", "v" }, "<leader>cr", function()
            vim.lsp.buf.code_action({
              context = { only = { "refactor" }, diagnostics = {} },
            })
          end, vim.tbl_extend("force", opts, { desc = "Refactor" }))

          -- Extract (visual mode) - for extracting functions/variables
          vim.keymap.set("v", "<leader>ce", function()
            vim.lsp.buf.code_action({
              context = { only = { "refactor.extract" }, diagnostics = {} },
            })
          end, vim.tbl_extend("force", opts, { desc = "Extract" }))

          -- Quick fix for current line
          vim.keymap.set("n", "<leader>cq", function()
            vim.lsp.buf.code_action({
              context = { only = { "quickfix" }, diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 }) },
            })
          end, vim.tbl_extend("force", opts, { desc = "Quick fix (line)" }))

          -- Format document (Ruff)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, vim.tbl_extend("force", opts, { desc = "Format document" }))

          -- Workspace commands
          vim.keymap.set(
            "n",
            "<leader>wa",
            vim.lsp.buf.add_workspace_folder,
            vim.tbl_extend("force", opts, { desc = "Add workspace folder" })
          )

          vim.keymap.set(
            "n",
            "<leader>wr",
            vim.lsp.buf.remove_workspace_folder,
            vim.tbl_extend("force", opts, { desc = "Remove workspace folder" })
          )

          vim.keymap.set("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, vim.tbl_extend("force", opts, { desc = "List workspace folders" }))

          -- Highlight symbol under cursor
          if client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Server-specific on_attach logic
          if client.name == "ruff" then
            -- Disable hover in favor of basedpyright
            client.server_capabilities.hoverProvider = false

            -- Create user command for organize imports
            vim.api.nvim_buf_create_user_command(bufnr, "RuffOrganizeImports", function()
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports.ruff" }, diagnostics = {} },
                apply = true,
              })
            end, { desc = "Ruff: Organize Imports" })

            -- Create user command for fix all
            vim.api.nvim_buf_create_user_command(bufnr, "RuffFixAll", function()
              vim.lsp.buf.code_action({
                context = { only = { "source.fixAll.ruff" }, diagnostics = {} },
                apply = true,
              })
            end, { desc = "Ruff: Fix All" })
          elseif client.name == "pylsp" then
            -- Disable capabilities handled by basedpyright/ruff LSP
            client.server_capabilities.hoverProvider = false
            client.server_capabilities.completionProvider = nil
            client.server_capabilities.definitionProvider = false
            client.server_capabilities.referencesProvider = false
            client.server_capabilities.documentHighlightProvider = false
            client.server_capabilities.documentSymbolProvider = false
            client.server_capabilities.workspaceSymbolProvider = false
            client.server_capabilities.signatureHelpProvider = nil
            -- Keep formatting disabled (ruff LSP handles it)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      })

      -- Mason-lspconfig simplified (Neovim 0.12+ pattern)
      -- No handlers block, no automatic_installation
      require("mason-lspconfig").setup({
        ensure_installed = { "basedpyright", "ruff", "pylsp", "lua_ls", "bashls", "jdtls", "taplo" },
        -- v2 defaults this to true, which enables *every* installed Mason package
        -- nvim-lspconfig ships an lsp/*.lua for — not just ensure_installed. With
        -- ~90 packages installed that meant pyright racing basedpyright on every
        -- Python buffer, and stylua attaching as an LSP server on top of the
        -- none-ls copy (formatting Lua twice). register_server() below is the
        -- single source of truth for what actually runs.
        automatic_enable = false,
      })

      -- Configure each server with vim.lsp.config (Neovim 0.12+ API)

      -- basedpyright configuration
      register_server("basedpyright", {
        capabilities = capabilities,
        settings = {
          basedpyright = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
              typeCheckingMode = "basic",
              autoImportCompletions = true, -- Enable auto-import code actions
            },
          },
          python = {
            pythonPath = get_python_path(),
          },
        },
        root_markers = {
          "pyproject.toml",
          "setup.py",
          "setup.cfg",
          "requirements.txt",
          "Pipfile",
          ".git",
        },
      })

      -- ruff configuration
      --- @type string
      --- @type vim.lsp.Config
      register_server("ruff", {
        capabilities = capabilities,
        init_options = {
          ---@type lspconfig.settings.ruff
          settings = {
            organizeImports = true,
            fixAll = true,
          },
        },
      })

      -- pylsp configuration (for refactoring with rope and diagnostics with python-lsp-ruff)
      --- @type string
      --- @type vim.lsp.Config
      register_server("pylsp", {
        capabilities = capabilities,
        ---@type lspconfig.settings.pylsp
        settings = {
          pylsp = {
            plugins = {
              -- Enable rope for refactoring (pylsp-rope plugin)
              pylsp_rope = { enabled = true },
              rope_autoimport = { enabled = false },
              rope_completion = { enabled = false },
              rope_rename = { enabled = true },

              -- Disable ruff in pylsp (standalone ruff LSP handles diagnostics)
              -- python-lsp-ruff must be disabled to avoid duplicate diagnostics
              ruff = { enabled = false },

              -- Explicitly disable other diagnostic/linting plugins
              jedi_completion = { enabled = false },
              jedi_hover = { enabled = false },
              jedi_references = { enabled = false },
              jedi_signature_help = { enabled = false },
              jedi_symbols = { enabled = false },
              jedi_definition = { enabled = false },
              pylint = { enabled = false },
              flake8 = { enabled = false },
              pylsp_mypy = { enabled = false },
              pydocstyle = { enabled = false },
            },
          },
        },
      })

      -- lua_ls configuration
      -- workspace.library has a hard floor here ($VIMRUNTIME + luv/luassert
      -- stubs) so `vim.*` intellisense works even if lazydev hasn't attached
      -- yet (ft=lua loading can race LspAttach). lazydev then layers plugin
      -- libraries on top dynamically.
      --- @type string
      --- @type vim.lsp.Config
      register_server("lua_ls", {
        capabilities = capabilities,
        --- @type lspconfig.settings.lua_ls
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
              path = { "lua/?.lua", "lua/?/init.lua" },
            },
            diagnostics = { globals = { "vim", "Snacks" } },
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
                "${3rd}/luv/library",
                "${3rd}/luassert/library",
              },
              -- Neovim's vimfn.gen.lua (~420 KB) and api.gen.lua (~110 KB)
              -- exceed lua-language-server's default preloadFileSize of 100 KB
              -- and would be silently skipped — breaking type info for
              -- `vim.fn.*` and `vim.api.*`. Bump the ceiling to 2 MB.
              preloadFileSize = 2000,
              maxPreload = 10000,
              -- Test mocks reassign `vim.lsp`, `vim.fn`, etc. to narrow
              -- stubs. Without ignoring them, lua_ls treats those stubs as
              -- the authoritative shape of the globals and shadows the
              -- meta files under $VIMRUNTIME.
              ignoreDir = { "tests/mocks" },
            },
            telemetry = { enable = false },
          },
        },
      })

      -- jdtls (Java) configuration
      local java_home = vim.env.JAVA_HOME
      if not java_home or java_home == "" then
        vim.notify("JAVA_HOME not set — jdtls will not start", vim.log.levels.WARN)
      else
        local jdtls_workspace = vim.fn.stdpath("cache") .. "/jdtls/workspace/"

        ---@type string
        ---@type vim.lsp.ClientConfig
        register_server("jdtls", {
          capabilities = capabilities,
          cmd = {
            "jdtls",
            "-data",
            jdtls_workspace .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
          },
          cmd_env = {
            JAVA_HOME = java_home,
          },
          ---@type lspconfig.settings.jdtls
          settings = {
            java = {
              home = java_home,
              configuration = {
                runtimes = {
                  {
                    name = "JavaSE-21",
                    path = java_home,
                    default = true,
                  },
                },
              },
              maven = { downloadSources = true },
              signatureHelp = { enabled = true },
              contentProvider = { preferred = "fernflower" },
              completion = {
                favoriteStaticMembers = {
                  "org.junit.Assert.*",
                  "org.junit.Assume.*",
                  "org.junit.jupiter.api.Assertions.*",
                  "org.mockito.Mockito.*",
                  "org.mockito.ArgumentMatchers.*",
                },
              },
              sources = {
                organizeImports = {
                  starThreshold = 9999,
                  staticStarThreshold = 9999,
                },
              },
            },
          },
          root_markers = {
            "pom.xml",
            "build.gradle",
            "build.gradle.kts",
            "settings.gradle",
            "settings.gradle.kts",
            ".git",
          },
        })
      end

      -- bashls configuration
      ---@type string
      ---@type lspconfig.Config
      register_server("bashls", {
        capabilities = capabilities,
        ---@type lspconfig.settings.bashls
        settings = {
          bashIde = {
            globPattern = "*@(.sh|.inc|.bash|.command|.zsh|.zshrc|.zshenv|.zprofile|.zlogin|.zlogout)",
          },
        },
        cmd = { "bash-language-server", "start" },
        filetypes = { "sh", "zsh", "bash" },
        cmd_env = {
          DEBUG = "true",
        },
      })

      -- taplo (TOML) configuration
      register_server("taplo", {
        capabilities = capabilities,
        settings = {
          evenBetterToml = {
            schema = {
              associations = {
                [".*/\\.config/jj/config\\.toml"] = "https://jj-vcs.github.io/jj/latest/config-schema.json",
              },
            },
          },
        },
      })

      register_server("rust_analyzer", {
        capabilities = capabilities,
      })

      -- Enable all configured servers (Neovim 0.12+ API)
      -- Sorted, and kept as an *array* rather than a name -> toggle_id map:
      -- toggle keys are handed out positionally from toggle_keyset below, so
      -- iterating with pairs() would reshuffle every <leader>tl<key> binding
      -- between sessions. ipairs over a sorted list keeps them stable.
      ---@type string[]
      local server_names = vim.tbl_keys(lsp_servers)
      table.sort(server_names)

      -- Generate a list of keys for mapping
      local toggle_keyset = {} ---@type string[]
      for i = 1, 10, 1 do
        toggle_keyset[#toggle_keyset + 1] = tostring(i % 10)
      end
      for i = string.byte("a"), string.byte("z") do
        local char = string.char(i)
        if char ~= "l" and char ~= "t" then
          toggle_keyset[#toggle_keyset + 1] = char
        end
      end

      -- Enable servers first, on their own. Toggle registration below needs
      -- Snacks, which is absent under the headless unit tests (--noplugin) and
      -- during early startup — folding both into one loop meant a nil Snacks
      -- aborted the loop partway and silently left later servers disabled.
      for _, server in ipairs(server_names) do
        vim.lsp.enable(server)
      end

      local all_lsp_toggles = {} ---@type table<string, snacks.toggle.Class>

      if Snacks and Snacks.toggle then
        for i, server in ipairs(server_names) do
          local toggle_id = "lsp_" .. server
          local t = Snacks.toggle.new({
            id = toggle_id,
            name = server:sub(1, 1):upper() .. server:sub(2),

            ---sets new value
            ---@param newval boolean
            set = function(newval)
              vim.lsp.enable(server, newval)
            end,

            ---returns current value
            ---@return boolean
            get = function()
              return vim.lsp.is_enabled(server)
            end,
          })
          all_lsp_toggles[toggle_id] = t

          -- More servers than available keys would index past the end of
          -- toggle_keyset and concatenate nil, taking down the whole config.
          local keymap = toggle_keyset[i]
          if keymap then
            t:map("<leader>tl" .. keymap, { mode = { "n", "v" } })
          else
            vim.notify(("No toggle key left for %s (>%d servers)"):format(server, #toggle_keyset), vim.log.levels.WARN)
          end
        end

        local toggle_all = Snacks.toggle.new({
          id = "lsp_toggle_all",
          name = "Toggle All LSPs",
          get = function()
            ---gets all enabled servers
            ---@param toggle snacks.toggle.Class
            return vim.iter(all_lsp_toggles):any(function(_, toggle)
              return toggle:get()
            end)
          end,
          set = function(state)
            for _, t in pairs(all_lsp_toggles) do
              t:set(state)
            end
          end,
        })
        toggle_all:map("<leader>tll")
      end

      -- Configure diagnostics (Neovim 0.12+ API with inline sign text)
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          source = "if_many",
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
          header = "",
          prefix = "",
        },
      })
    end,
  },
}
