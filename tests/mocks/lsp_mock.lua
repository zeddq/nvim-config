-- Mock module for LSP-related packages (mason, mason-lspconfig, cmp_nvim_lsp)
-- and vim.lsp.config / vim.lsp.enable call capture.
--
-- Usage:
--   local lsp_mock = require("mocks.lsp_mock")
--   lsp_mock.install()
--   -- ... run code that calls vim.lsp.config/enable and requires mason* ...
--   assert(lsp_mock.calls.configs["ruff"] ~= nil)
--   lsp_mock.uninstall()

local M = {}

-- Call log exposed to tests
M.calls = {
  configs = {},       -- name -> opts (last call wins)
  config_order = {},  -- list of names in call order
  enables = {},       -- name -> true
  enable_order = {},  -- list of names in call order
  mason_setup = nil,
  mason_lspconfig_setup = nil, -- captured opts incl. ensure_installed
  cmp_default_caps_calls = 0,
}

-- Save originals so we can restore on uninstall
local _orig = {
  lsp_config = nil,
  lsp_enable = nil,
  had_lsp_config = false,
  had_lsp_enable = false,
}

local _installed = false

function M.reset()
  M.calls = {
    configs = {},
    config_order = {},
    enables = {},
    enable_order = {},
    mason_setup = nil,
    mason_lspconfig_setup = nil,
    cmp_default_caps_calls = 0,
  }
end

function M.install()
  if _installed then
    M.reset()
    return
  end
  M.reset()

  -- Clear cached loaded modules so preload takes effect
  package.loaded["mason"] = nil
  package.loaded["mason-lspconfig"] = nil
  package.loaded["cmp_nvim_lsp"] = nil

  package.preload["mason"] = function()
    return {
      setup = function(opts)
        M.calls.mason_setup = opts or {}
      end,
    }
  end

  package.preload["mason-lspconfig"] = function()
    return {
      setup = function(opts)
        M.calls.mason_lspconfig_setup = opts or {}
      end,
    }
  end

  package.preload["cmp_nvim_lsp"] = function()
    return {
      default_capabilities = function(caps)
        M.calls.cmp_default_caps_calls = M.calls.cmp_default_caps_calls + 1
        return caps or {}
      end,
    }
  end

  -- Monkey-patch vim.lsp.config / vim.lsp.enable
  vim.lsp = vim.lsp or {}
  _orig.had_lsp_config = rawget(vim.lsp, "config") ~= nil
  _orig.had_lsp_enable = rawget(vim.lsp, "enable") ~= nil
  _orig.lsp_config = rawget(vim.lsp, "config")
  _orig.lsp_enable = rawget(vim.lsp, "enable")

  vim.lsp.config = function(name, opts)
    M.calls.configs[name] = opts or {}
    table.insert(M.calls.config_order, name)
  end
  vim.lsp.enable = function(name)
    -- name can be a string or a list of strings
    if type(name) == "table" then
      for _, n in ipairs(name) do
        M.calls.enables[n] = true
        table.insert(M.calls.enable_order, n)
      end
    else
      M.calls.enables[name] = true
      table.insert(M.calls.enable_order, name)
    end
  end

  _installed = true
end

function M.uninstall()
  if not _installed then
    return
  end
  package.preload["mason"] = nil
  package.preload["mason-lspconfig"] = nil
  package.preload["cmp_nvim_lsp"] = nil
  package.loaded["mason"] = nil
  package.loaded["mason-lspconfig"] = nil
  package.loaded["cmp_nvim_lsp"] = nil

  if _orig.had_lsp_config then
    vim.lsp.config = _orig.lsp_config
  else
    vim.lsp.config = nil
  end
  if _orig.had_lsp_enable then
    vim.lsp.enable = _orig.lsp_enable
  else
    vim.lsp.enable = nil
  end

  _installed = false
end

return M
