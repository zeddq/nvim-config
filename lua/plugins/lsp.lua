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

      -- Get capabilities from cmp_nvim_lsp first
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

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

        -- Fallback to system python
        return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
      end

      -- LspAttach autocmd for on_attach logic (Neovim 0.12+ pattern)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf

          if not client then
            return
          end

          local opts = { buffer = bufnr, silent = true }

          -- LSP keybindings
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set(
            "n",
            "gD",
            vim.lsp.buf.declaration,
            vim.tbl_extend("force", opts, { desc = "Go to declaration" })
          )
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
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
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
          if client.name == "bashls" then
            print("bashls attached to buffer " .. bufnr)
          elseif client.name == "ruff" then
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
      })

      -- Configure each server with vim.lsp.config (Neovim 0.12+ API)

      -- basedpyright configuration
      vim.lsp.config("basedpyright", {
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
      vim.lsp.config("ruff", {
        capabilities = capabilities,
        init_options = {
          settings = {
            organizeImports = true,
            fixAll = true,
          },
        },
      })

      -- pylsp configuration (for refactoring with rope and diagnostics with python-lsp-ruff)
      vim.lsp.config("pylsp", {
        capabilities = capabilities,
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
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
            },
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = {
                vim.env.VIMRUNTIME,
                "${3rd}/luv/library",
                "${3rd}/luassert/library",
              },
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })

      -- jdtls (Java) configuration
      local java_home = vim.env.JAVA_HOME
      if not java_home or java_home == "" then
        vim.notify("JAVA_HOME not set — jdtls will not start", vim.log.levels.WARN)
      else
      local jdtls_workspace = vim.fn.stdpath("cache") .. "/jdtls/workspace/"

      vim.lsp.config("jdtls", {
        capabilities = capabilities,
        cmd = {
          "jdtls",
          "-data",
          jdtls_workspace .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
        },
        cmd_env = {
          JAVA_HOME = java_home,
        },
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
            eclipse = { downloadSources = true },
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
      vim.lsp.enable("jdtls")
      end

      -- bashls configuration
      vim.lsp.config("bashls", {
        capabilities = capabilities,
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
      vim.lsp.config("taplo", {
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

      -- Enable all configured servers (Neovim 0.12+ API)
      vim.lsp.enable("basedpyright")
      vim.lsp.enable("ruff")
      vim.lsp.enable("pylsp")
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("bashls")
      vim.lsp.enable("taplo")

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
          source = "always",
          header = "",
          prefix = "",
        },
      })
    end,
  },
}
