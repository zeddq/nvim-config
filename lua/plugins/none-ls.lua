-- none-ls (null-ls successor) Configuration
-- Provides formatting, linting, and code actions via LSP

return {
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local null_ls = require("null-ls")
      local h = require("null-ls.helpers")

      -- Formatting and diagnostics sources
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      -- Custom AppleScript diagnostics using osacompile (on-save only)
      -- Uses actual file for validation since osacompile requires file path
      local applescript_diagnostics = h.make_builtin({
        name = "osacompile",
        meta = {
          url = "https://developer.apple.com/library/archive/documentation/AppleScript/",
          description = "AppleScript syntax validation using osacompile",
        },
        method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
        filetypes = { "applescript" },
        generator_opts = {
          command = "osacompile",
          args = { "-o", "/dev/null", "$FILENAME" },
          to_stdin = false,
          from_stderr = true,
          format = "line",
          check_exit_code = function(code)
            return code <= 1
          end,
          on_output = h.diagnostics.from_pattern(
            [[(%d+):%s*(%w+):%s*(.-)%.%s*%(?%-?%d+%)?]],
            { "row", "severity", "message" },
            {
              severities = {
                error = h.diagnostics.severities["error"],
                warning = h.diagnostics.severities["warning"],
              },
              defaults = {
                severity = h.diagnostics.severities["error"],
              },
            }
          ),
        },
        factory = h.generator_factory,
      })

      -- Real-time AppleScript diagnostics using temp file
      -- This enables diagnostics while editing (before save)
      local applescript_diagnostics_realtime = h.make_builtin({
        name = "osacompile_realtime",
        meta = {
          url = "https://developer.apple.com/library/archive/documentation/AppleScript/",
          description = "Real-time AppleScript validation using temp file",
        },
        method = null_ls.methods.DIAGNOSTICS,
        filetypes = { "applescript" },
        generator = {
          fn = function(params)
            local temp_file = os.tmpname() .. ".applescript"

            -- Write buffer content to temp file
            local file = io.open(temp_file, "w")
            if not file then
              return {}
            end
            file:write(table.concat(params.content, "\n"))
            file:close()

            -- Run osacompile on temp file
            local handle = io.popen("osacompile -o /dev/null '" .. temp_file .. "' 2>&1")
            if not handle then
              os.remove(temp_file)
              return {}
            end

            local result = handle:read("*a")
            handle:close()
            os.remove(temp_file)

            -- Parse diagnostics
            local diagnostics = {}
            for line in result:gmatch("[^\r\n]+") do
              local row, severity, message = line:match("(%d+):%s*(%w+):%s*(.-)%.%s*%(?%-?%d+%)?")
              if row and message then
                table.insert(diagnostics, {
                  row = tonumber(row),
                  col = 1,
                  message = message,
                  severity = severity:lower() == "error" and 1 or 2,
                  source = "osacompile",
                })
              end
            end

            return diagnostics
          end,
        },
      })

      -- AppleScript formatter using osadecompile
      -- This normalizes formatting and works for both .applescript and .scpt files
      -- Uses buffer content (not disk file) to avoid BufWritePre timing issues
      local applescript_formatter = h.make_builtin({
        name = "osadecompile",
        meta = {
          url = "https://developer.apple.com/library/archive/documentation/AppleScript/",
          description = "AppleScript formatter using osadecompile (normalizes code style)",
        },
        method = null_ls.methods.FORMATTING,
        filetypes = { "applescript" },
        generator = {
          fn = function(params)
            -- Create temp files
            local temp_source = os.tmpname() .. ".applescript"
            local temp_compiled = os.tmpname() .. ".scpt"

            -- Write buffer content to temp file
            local file = io.open(temp_source, "w")
            if not file then
              return nil -- Formatting fails gracefully
            end
            file:write(table.concat(params.content, "\n"))
            file:close()

            -- Compile to binary, then decompile for formatting
            local cmd = string.format(
              "osacompile -o '%s' '%s' 2>/dev/null && osadecompile '%s' 2>/dev/null",
              temp_compiled,
              temp_source,
              temp_compiled
            )
            local handle = io.popen(cmd)
            if not handle then
              os.remove(temp_source)
              return nil
            end

            local formatted = handle:read("*a")
            local success = handle:close()

            -- Cleanup
            os.remove(temp_source)
            os.remove(temp_compiled)

            -- Only return formatted output if compilation succeeded
            if success and formatted and #formatted > 0 then
              return { { text = formatted } }
            else
              -- Return nil to keep original formatting if compilation fails
              return nil
            end
          end,
        },
      })

      -- AppleScript code actions for common fixes
      local applescript_code_actions = h.make_builtin({
        name = "applescript_actions",
        meta = {
          description = "Code actions for common AppleScript fixes",
        },
        method = null_ls.methods.CODE_ACTION,
        filetypes = { "applescript" },
        generator = {
          fn = function(params)
            local actions = {}
            local diagnostics = params.lsp_params.context.diagnostics or {}

            for _, diagnostic in ipairs(diagnostics) do
              local message = diagnostic.message or ""

              -- Action: Add missing "end tell"
              if message:match("Expected.*end tell") then
                table.insert(actions, {
                  title = "Add 'end tell'",
                  action = function()
                    local row = diagnostic.range["end"].line + 1
                    vim.api.nvim_buf_set_lines(params.bufnr, row, row, false, { "end tell" })
                  end,
                })
              end

              -- Action: Add missing "end repeat"
              if message:match("Expected.*end repeat") then
                table.insert(actions, {
                  title = "Add 'end repeat'",
                  action = function()
                    local row = diagnostic.range["end"].line + 1
                    vim.api.nvim_buf_set_lines(params.bufnr, row, row, false, { "end repeat" })
                  end,
                })
              end

              -- Action: Add missing "end if"
              if message:match("Expected.*end if") then
                table.insert(actions, {
                  title = "Add 'end if'",
                  action = function()
                    local row = diagnostic.range["end"].line + 1
                    vim.api.nvim_buf_set_lines(params.bufnr, row, row, false, { "end if" })
                  end,
                })
              end

              -- Action: Close unclosed string
              if message:match("Expected.*[\"']") or message:match("unterminated string") then
                table.insert(actions, {
                  title = "Close string with double quote",
                  action = function()
                    local row = diagnostic.range["end"].line
                    local line = vim.api.nvim_buf_get_lines(params.bufnr, row, row + 1, false)[1]
                    vim.api.nvim_buf_set_lines(params.bufnr, row, row + 1, false, { line .. '"' })
                  end,
                })
              end
            end

            return actions
          end,
        },
      })

      null_ls.setup({
        debug = false,
        sources = {
          -- AppleScript
          applescript_diagnostics,          -- On-save diagnostics
          applescript_diagnostics_realtime, -- Real-time diagnostics while editing
          applescript_formatter,
          applescript_code_actions,

          -- Lua
          formatting.stylua.with({
            extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
          }),

          -- Python formatting handled by ruff LSP (not none-ls)

          -- JavaScript/TypeScript
          formatting.prettier.with({
            prefer_local = "node_modules/.bin",
            extra_filetypes = { "toml" },
          }),

          -- JSON/YAML
          formatting.prettier.with({
            filetypes = { "json", "jsonc", "yaml" },
          }),

          -- Markdown
          formatting.prettier.with({
            filetypes = { "markdown" },
          }),
          diagnostics.markdownlint,

          -- Shell scripts
          formatting.shfmt.with({
            filetypes = { "sh", "zsh", "bash" },
            extra_args = { "-i", "2", "-ci" },
          }),

          -- Go
          formatting.gofmt,
          formatting.goimports,

          -- SQL
          formatting.sqlformat,

          -- General code actions
          code_actions.gitsigns,
        },

        -- Configure formatting on save
        on_attach = function(client, bufnr)
          if client:supports_method("textDocument/formatting") then
            local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = false })
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
                if filetype == "applescript" then
                  local diagnostics = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
                  if #diagnostics > 0 then
                    return
                  end
                end

                local ok, err = pcall(function()
                  vim.lsp.buf.format({
                    bufnr = bufnr,
                    filter = function(formatting_client)
                      return formatting_client.name == "null-ls"
                    end,
                    timeout_ms = 5000,
                    async = false,
                  })
                end)
                if not ok then
                  vim.notify("Formatting failed: " .. tostring(err), vim.log.levels.WARN)
                end
              end,
            })
          end
        end,
      })

      -- Keymaps for manual formatting
      vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "Format buffer" })
      vim.keymap.set("v", "<leader>gf", vim.lsp.buf.format, { desc = "Format selection" })
    end,
  },

  -- Optional: Mason integration for automatic tool installation
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    config = function()
      require("mason-null-ls").setup({
        ensure_installed = {
          "stylua",
          "ruff", -- Replaces black, isort, and pylint for Python
          "prettier",
          "markdownlint",
          "shfmt",
        },
        -- Disable automatic handlers - we configure sources manually in none-ls
        handlers = {
          -- Explicitly ignore pylint (we use ruff instead)
          pylint = function() end,
          black = function() end,
          isort = function() end,
        },
      })
    end,
  },
}
