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

      -- Formatting and diagnostics sources
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      null_ls.setup({
        debug = false,
        sources = {
          -- Lua
          formatting.stylua.with({
            extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
          }),

          -- Python
          formatting.black.with({
            extra_args = { "--fast" },
          }),
          formatting.isort,
          diagnostics.pylint.with({
            prefer_local = ".venv/bin",
          }),

          -- JavaScript/TypeScript
          formatting.prettier.with({
            prefer_local = "node_modules/.bin",
            extra_filetypes = { "toml" },
          }),
          -- NOTE: eslint_d removed from none-ls builtins
          -- Use eslint LSP server or nvim-lint instead
          -- diagnostics.eslint_d.with({
          --   prefer_local = 'node_modules/.bin',
          -- }),
          -- code_actions.eslint_d.with({
          --   prefer_local = 'node_modules/.bin',
          -- }),

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
          -- NOTE: shellcheck removed from none-ls builtins
          -- Use shellcheck via LSP or nvim-lint instead
          -- diagnostics.shellcheck,

          -- Go
          formatting.gofmt,
          formatting.goimports,

          -- Rust
          -- NOTE: rustfmt removed from none-ls builtins
          -- Use rust-analyzer LSP formatting instead
          -- formatting.rustfmt,

          -- SQL
          formatting.sqlformat,

          -- General code actions
          code_actions.gitsigns,
        },

        -- Configure formatting on save
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = false })
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({
                  bufnr = bufnr,
                  filter = function(formatting_client)
                    -- Only use none-ls for formatting
                    return formatting_client.name == "null-ls"
                  end,
                  timeout_ms = 2000,
                })
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
          -- Lua
          "stylua",

          -- Python
          "black",
          "isort",
          "pylint",

          -- JavaScript/TypeScript
          "prettier",
          -- 'eslint_d',  -- Removed: not available in none-ls builtins

          -- Markdown
          "markdownlint",

          -- Shell
          "shfmt",
          -- 'shellcheck',  -- Removed: not available in none-ls builtins

          -- SQL
          "sqlformat",
        },
        automatic_installation = true,
        handlers = {},
      })
    end,
  },
}
