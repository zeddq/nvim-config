-- conform.nvim Configuration
-- Modern formatting with automatic diagnostic refresh
-- This is complementary to ruff LSP - handles formatting, ruff LSP handles diagnostics

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "Format buffer (Conform)",
    },
  },
  opts = {
    formatters_by_ft = {
      python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      lua = { "stylua" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
    },

    -- Format on save configuration
    format_on_save = function(bufnr)
      -- Disable for certain filetypes or conditions
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return
      end
      return {
        timeout_ms = 500,
        lsp_fallback = true,
      }
    end,

    -- Customize formatters
    formatters = {
      ruff_fix = {
        -- Run ruff --fix to auto-fix linting issues
        command = "ruff",
        args = { "check", "--fix", "--stdin-filename", "$FILENAME", "-" },
        stdin = true,
      },
      ruff_format = {
        -- Run ruff format for code style
        command = "ruff",
        args = { "format", "--stdin-filename", "$FILENAME", "-" },
        stdin = true,
      },
      ruff_organize_imports = {
        -- Run ruff to organize imports
        command = "ruff",
        args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" },
        stdin = true,
      },
      shfmt = {
        prepend_args = { "-i", "2", "-ci" },
      },
      stylua = {
        prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
      },
    },
  },

  config = function(_, opts)
    require("conform").setup(opts)

    -- Create user commands
    vim.api.nvim_create_user_command("Format", function(args)
      local range = nil
      if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = {
          start = { args.line1, 0 },
          ["end"] = { args.line2, end_line:len() },
        }
      end
      require("conform").format({ async = true, lsp_fallback = true, range = range })
    end, { range = true, desc = "Format buffer or range" })

    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        -- Disable for all buffers
        vim.g.disable_autoformat = true
      else
        -- Disable for current buffer
        vim.b.disable_autoformat = true
      end
    end, { bang = true, desc = "Disable autoformat" })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, { desc = "Enable autoformat" })
  end,
}
