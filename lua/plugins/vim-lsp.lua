-- Alternative LSP Configuration using vim-lsp and vim-lsp-settings
-- NOTE: This is an alternative to the nvim-lspconfig setup in lsp.lua
-- To use this instead, comment out the lsp.lua import in plugins/init.lua
-- and uncomment the vim-lsp.lua import

return {
  {
    'mattn/vim-lsp-settings',
    dependencies = { 'prabirshrestha/vim-lsp' },
    init = function()
      -- Prettier configuration for efm-langserver
      local prettierd_candidates = {
        vim.fn.expand("~/.config/nvim/utils/linter-config/.prettierrc.json"),
        vim.fn.expand("~/.config/prettier/.prettierrc.json"),
        vim.fn.expand("~/.config/prettier/.prettierrc"),
        vim.fn.expand("~/.prettierrc.json"),
        vim.fn.expand("~/.prettierrc"),
      }

      local default_prettier_config
      for _, path in ipairs(prettierd_candidates) do
        if vim.fn.filereadable(path) == 1 then
          default_prettier_config = path
          break
        end
      end

      if default_prettier_config then
        vim.env.PRETTIERD_DEFAULT_CONFIG = default_prettier_config
      end

      local function make_prettierd_config()
        local cfg = {
          formatCommand = 'prettierd "${INPUT}"',
          formatStdin = true,
        }
        if default_prettier_config then
          cfg.env = { string.format("PRETTIERD_DEFAULT_CONFIG=%s", default_prettier_config) }
        end
        return cfg
      end

      local prettierd_languages = {
        javascript = { make_prettierd_config() },
        javascriptreact = { make_prettierd_config() },
        typescript = { make_prettierd_config() },
        typescriptreact = { make_prettierd_config() },
        json = { make_prettierd_config() },
        yaml = { make_prettierd_config() },
        html = { make_prettierd_config() },
        css = { make_prettierd_config() },
        scss = { make_prettierd_config() },
        markdown = { make_prettierd_config() },
      }

      local efm_filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "yaml",
        "html",
        "css",
        "scss",
        "markdown",
      }

      vim.g.__lsp_settings_efm_allowlist = efm_filetypes

      -- Configure efm-langserver binary path
      local efm_binary = vim.fn.exepath("efm-langserver")
      if efm_binary == "" then
        efm_binary = vim.fn.expand("~/.local/share/vim-lsp-settings/servers/efm-langserver/efm-langserver")
      end
      local efm_cmd = {}
      if efm_binary ~= "" then
        table.insert(efm_cmd, efm_binary)
        local efm_config = vim.fn.expand("~/.config/efm-langserver/config.yaml")
        if vim.fn.filereadable(efm_config) == 1 then
          table.insert(efm_cmd, "-c")
          table.insert(efm_cmd, efm_config)
        end
      end

      -- LSP server settings
      vim.g.lsp_settings = vim.tbl_deep_extend("force", vim.g.lsp_settings or {}, {
        ["efm-langserver"] = {
          disabled = false,
          allowlist = efm_filetypes,
          initialization_options = {
            documentFormatting = true,
            documentRangeFormatting = true,
            languages = prettierd_languages,
          },
          cmd = efm_cmd,
        },
        ["javascript-typescript-stdio"] = { disabled = true },
      })

      -- Configure which LSP servers to use for each filetype
      local filetype_servers = {
        javascript = { "typescript-language-server", "efm-langserver" },
        javascriptreact = { "typescript-language-server", "efm-langserver" },
        typescript = { "typescript-language-server", "efm-langserver" },
        typescriptreact = { "typescript-language-server", "efm-langserver" },
        json = { "json-languageserver", "efm-langserver" },
        yaml = { "yaml-language-server", "efm-langserver" },
        html = { "html-languageserver", "efm-langserver" },
        css = { "css-languageserver", "efm-langserver" },
        scss = { "css-languageserver", "efm-langserver" },
        markdown = { "marksman", "efm-langserver" },
      }

      for ft, servers in pairs(filetype_servers) do
        vim.g["lsp_settings_filetype_" .. ft] = servers
      end
    end,
    config = function()
      local format_fn = vim.fn["lsp#internal#document_formatting#format"]
      if type(format_fn) ~= "function" then
        vim.notify("[vim-lsp-settings] document_formatting helper missing", vim.log.levels.WARN)
        return
      end

      -- Setup format-on-save for configured filetypes
      local format_filetypes = {}
      local allowlist = vim.g.__lsp_settings_efm_allowlist or {}
      for _, ft in ipairs(allowlist) do
        format_filetypes[ft] = true
      end

      local format_group = vim.api.nvim_create_augroup("LspSettingsPrettierdFormat", { clear = false })
      vim.api.nvim_create_autocmd("User", {
        pattern = "lsp_buffer_enabled",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local ft = vim.bo[buf].filetype
          if not format_filetypes[ft] then
            return
          end
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = format_group,
            buffer = buf,
            callback = function()
              local ok_fmt, err = pcall(vim.cmd, "silent! LspDocumentFormatSync")
              if not ok_fmt then
                vim.notify(string.format("[vim-lsp] efm format failed: %s", err), vim.log.levels.WARN)
              end
            end,
          })
        end,
      })
    end,
  },
}
