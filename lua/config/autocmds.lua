-- Neovim Autocommands Configuration
-- Automatic actions on events

local augroup = vim.api.nvim_create_augroup("UserAutoCommands", { clear = true })

-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
  desc = "Remove trailing whitespace on save",
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  pattern = "*",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
  desc = "Highlight yanked text",
})

-- Close certain filetypes with 'q'
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "lspinfo", "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
  desc = "Close with q",
})

-- Python-specific settings
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
  desc = "Python-specific settings",
})

-- Zsh filetype detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup,
  pattern = { ".zshrc", ".zshenv", ".zprofile", ".zlogin", ".zlogout", "*.zsh" },
  callback = function()
    vim.bo.filetype = "zsh"
  end,
  desc = "Set filetype for zsh config files",
})

-- Zsh-specific settings
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { ".zshrc", ".zshenv", ".zprofile", ".zlogin", ".zlogout", "*.zsh" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
    vim.opt_local.textwidth = 80
  end,
  desc = "Zsh-specific settings",
})

-- JJ resolve: 3-way merge keymaps in OUTPUT window
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
  group = augroup,
  callback = function()
    vim.schedule(function()
      local ok, jj_merge = pcall(require, "utils.jj_merge")
      if ok then
        jj_merge.setup_keymaps()
      end
    end)
  end,
  desc = "Setup jj resolve merge keymaps",
})
