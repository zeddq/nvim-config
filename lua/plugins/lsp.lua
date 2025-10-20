-- LSP Configuration with Mason and Pyright
-- Complete setup for Python development

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Mason for LSP server management
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      
      -- Additional capabilities
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      -- Setup Mason first
      require('mason').setup({
        ui = {
          border = 'rounded',
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })

      -- Get capabilities from cmp_nvim_lsp first
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      -- LSP on_attach function (defined before mason-lspconfig setup)
      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, silent = true }

        -- LSP keybindings
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Go to declaration' }))
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = 'Go to implementation' }))
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Show references' }))
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, { desc = 'Signature help' }))
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code action' }))
        vim.keymap.set('n', '<leader>f', function()
          vim.lsp.buf.format({ async = true })
        end, vim.tbl_extend('force', opts, { desc = 'Format document' }))

        -- Workspace commands
        vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, vim.tbl_extend('force', opts, { desc = 'Add workspace folder' }))
        vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, vim.tbl_extend('force', opts, { desc = 'Remove workspace folder' }))
        vim.keymap.set('n', '<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, vim.tbl_extend('force', opts, { desc = 'List workspace folders' }))

        -- Highlight symbol under cursor
        if client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup('LspDocumentHighlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = bufnr,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = bufnr,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end

      -- LSP server configuration
      local lspconfig = require('lspconfig')

      -- Mason-lspconfig with handlers for automatic server setup
      require('mason-lspconfig').setup({
        ensure_installed = { 'pyright', 'lua_ls' },
        automatic_installation = true,
        handlers = {
          -- Default handler for all servers
          function(server_name)
            lspconfig[server_name].setup({
              on_attach = on_attach,
              capabilities = capabilities,
            })
          end,

          -- Custom handler for pyright
          ['pyright'] = function()
            lspconfig.pyright.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              settings = {
                python = {
                  analysis = {
                    autoSearchPaths = true,
                    diagnosticMode = "workspace",
                    useLibraryCodeForTypes = true,
                    typeCheckingMode = "basic",
                  },
                },
              },
              root_dir = function(fname)
                local util = require('lspconfig.util')
                return util.root_pattern(
                  'pyproject.toml',
                  'setup.py',
                  'setup.cfg',
                  'requirements.txt',
                  'Pipfile',
                  '.git'
                )(fname) or util.path.dirname(fname)
              end,
            })
          end,

          -- Custom handler for lua_ls
          ['lua_ls'] = function()
            lspconfig.lua_ls.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { 'vim' },
                  },
                  workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                  },
                  telemetry = {
                    enable = false,
                  },
                },
              },
            })
          end,
        },
      })

      -- Configure diagnostics
      vim.diagnostic.config({
        virtual_text = {
          prefix = '●',
          source = 'if_many',
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = 'rounded',
          source = 'always',
          header = '',
          prefix = '',
        },
      })

      -- Diagnostic signs
      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    end,
  },
}
