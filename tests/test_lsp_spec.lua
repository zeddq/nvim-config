-- Test Suite: LSP Plugin Spec
-- Loads lua/plugins/lsp.lua and executes its `config` function with
-- mocked mason/mason-lspconfig/cmp_nvim_lsp and vim.lsp.config/enable
-- captured. Asserts servers, ensure_installed, ruff/pylsp disable
-- logic via the LspAttach callback, and that the LspAttach autocmd
-- registers the expected keymaps.

local script_dir = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

local lsp_mock = require("mocks.lsp_mock")

local results = { passed = 0, failed = 0, tests = {} }

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    results.passed = results.passed + 1
    table.insert(results.tests, { name = name, status = "PASS" })
    print(string.format("✓ %s", name))
  else
    results.failed = results.failed + 1
    table.insert(results.tests, { name = name, status = "FAIL", error = tostring(err) })
    print(string.format("✗ %s: %s", name, err))
  end
end

local function assert_true(cond, msg)
  if not cond then
    error(msg or "Expected truthy value")
  end
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error(string.format("%s: expected %s, got %s", msg or "assert_eq", tostring(b), tostring(a)))
  end
end

print("\n=== LSP Plugin Spec Tests ===\n")

-- Install mocks before loading the plugin spec
lsp_mock.install()

-- Drop cached spec so config() runs fresh
package.loaded["plugins.lsp"] = nil
local spec = require("plugins.lsp")
assert(type(spec) == "table", "plugins.lsp must return a table")

-- The spec is a list with a single entry (the lspconfig plugin)
local entry
for _, e in ipairs(spec) do
  if type(e) == "table" and e[1] == "neovim/nvim-lspconfig" then
    entry = e
    break
  end
end
assert(entry, "Expected nvim-lspconfig plugin entry in spec")

-- Stub JAVA_HOME so jdtls branch runs
local prev_java_home = vim.env.JAVA_HOME
vim.env.JAVA_HOME = vim.env.JAVA_HOME ~= nil and vim.env.JAVA_HOME ~= "" and vim.env.JAVA_HOME
  or "/tmp/fake-java-home"

-- Execute the config function — this runs all the setup code
local config_ok, config_err = pcall(entry.config, entry, entry.opts or {})
-- Restore
vim.env.JAVA_HOME = prev_java_home

test("config() executes without error", function()
  if not config_ok then
    error("config() raised: " .. tostring(config_err))
  end
end)

local captured_configs = lsp_mock.calls.configs
local captured_enables = lsp_mock.calls.enables

test("mason.setup was called", function()
  assert_true(lsp_mock.calls.mason_setup ~= nil, "mason.setup should have been invoked")
end)

test("mason-lspconfig.setup ensure_installed contains all 7 servers", function()
  local ml = lsp_mock.calls.mason_lspconfig_setup
  assert_true(ml ~= nil, "mason-lspconfig.setup should have been called")
  local ensure = ml.ensure_installed or {}
  local want = { "basedpyright", "ruff", "pylsp", "lua_ls", "bashls", "jdtls", "taplo" }
  local set = {}
  for _, s in ipairs(ensure) do set[s] = true end
  for _, s in ipairs(want) do
    assert_true(set[s], "ensure_installed missing server: " .. s)
  end
end)

test("cmp_nvim_lsp.default_capabilities was invoked", function()
  assert_true(lsp_mock.calls.cmp_default_caps_calls >= 1, "default_capabilities should be called")
end)

local expected_servers = { "basedpyright", "ruff", "pylsp", "lua_ls", "bashls", "jdtls", "taplo" }

for _, server in ipairs(expected_servers) do
  test("vim.lsp.config called for " .. server, function()
    assert_true(captured_configs[server] ~= nil, "No vim.lsp.config(" .. server .. ") captured")
  end)
  test("vim.lsp.enable called for " .. server, function()
    assert_true(captured_enables[server] == true, "No vim.lsp.enable(" .. server .. ") captured")
  end)
end

test("basedpyright config has settings.basedpyright.analysis", function()
  local cfg = captured_configs["basedpyright"]
  assert_true(cfg.settings and cfg.settings.basedpyright and cfg.settings.basedpyright.analysis,
    "basedpyright analysis settings missing")
end)

test("lua_ls integrates with lazydev-compatible workspace library", function()
  local cfg = captured_configs["lua_ls"]
  local lib = cfg.settings and cfg.settings.Lua and cfg.settings.Lua.workspace
    and cfg.settings.Lua.workspace.library
  assert_true(type(lib) == "table" and #lib > 0, "lua_ls workspace.library should be populated")
  -- Should include VIMRUNTIME so vim.* and vim.uv libraries are resolvable
  local has_vimruntime = false
  for _, p in ipairs(lib) do
    if p == vim.env.VIMRUNTIME or (type(p) == "string" and p:match("luv")) then
      has_vimruntime = true
    end
  end
  assert_true(has_vimruntime, "lua_ls workspace.library should reference VIMRUNTIME or luv library")
end)

test("pylsp config disables jedi_*, pylint, flake8, pylsp_mypy, pydocstyle, ruff", function()
  local cfg = captured_configs["pylsp"]
  local plugins = cfg.settings and cfg.settings.pylsp and cfg.settings.pylsp.plugins
  assert_true(plugins ~= nil, "pylsp plugins config missing")
  local disabled = {
    "ruff", "jedi_completion", "jedi_hover", "jedi_references",
    "jedi_signature_help", "jedi_symbols", "jedi_definition",
    "pylint", "flake8", "pylsp_mypy", "pydocstyle",
  }
  for _, name in ipairs(disabled) do
    local p = plugins[name]
    assert_true(p and p.enabled == false,
      "pylsp plugin '" .. name .. "' should be disabled (enabled=false)")
  end
end)

test("pylsp config enables rope-based refactoring", function()
  local cfg = captured_configs["pylsp"]
  local plugins = cfg.settings.pylsp.plugins
  -- pylsp_rope + rope_rename are the rope-based refactoring knobs.
  assert_true(plugins.pylsp_rope and plugins.pylsp_rope.enabled == true,
    "pylsp_rope should be enabled for refactoring")
  assert_true(plugins.rope_rename and plugins.rope_rename.enabled == true,
    "rope_rename should be enabled")
end)

-- LspAttach keymap verification: simulate a client attaching and observe
-- which buffer-local keymaps get registered. The ruff on_attach also
-- disables hoverProvider, so we'll verify that too.

local function find_lsp_attach_autocmd()
  local acs = vim.api.nvim_get_autocmds({ event = "LspAttach", group = "UserLspConfig" })
  return acs
end

test("LspAttach autocmd registered in UserLspConfig group", function()
  local acs = find_lsp_attach_autocmd()
  assert_true(#acs >= 1, "Expected at least one LspAttach autocmd in UserLspConfig")
end)

-- Fire the LspAttach callback manually by invoking the autocmd's callback with a stub client.
local captured_keymaps = {}
local orig_keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  -- record (mode, lhs)
  local modes = type(mode) == "table" and mode or { mode }
  for _, m in ipairs(modes) do
    table.insert(captured_keymaps, { mode = m, lhs = lhs, opts = opts })
  end
  -- don't actually install to avoid polluting state
end

-- Fake client for the LspAttach callback
local fake_client = {
  name = "ruff",
  server_capabilities = {
    hoverProvider = true,
    documentHighlightProvider = false,
  },
}
local orig_get_client = vim.lsp.get_client_by_id
vim.lsp.get_client_by_id = function(_id) return fake_client end

-- Stub nvim_buf_create_user_command so ruff branch doesn't bomb on fake bufnr
local orig_buf_create_cmd = vim.api.nvim_buf_create_user_command
vim.api.nvim_buf_create_user_command = function(_b, _n, _c, _o) end

local acs = find_lsp_attach_autocmd()
local attach_cb = acs[1].callback
local fake_args = { data = { client_id = 1 }, buf = 0 }
local cb_ok, cb_err = pcall(attach_cb, fake_args)

-- Restore
vim.keymap.set = orig_keymap_set
vim.lsp.get_client_by_id = orig_get_client
vim.api.nvim_buf_create_user_command = orig_buf_create_cmd

test("LspAttach callback executed without error", function()
  if not cb_ok then error("LspAttach callback failed: " .. tostring(cb_err)) end
end)

-- Collect set of (mode, lhs) pairs
local key_set = {}
for _, k in ipairs(captured_keymaps) do
  key_set[k.mode .. ":" .. k.lhs] = true
end

-- Expected keymaps based on the actual source (lsp.lua lines 74-143)
local expected_keys = {
  "n:gd", "n:gD", "n:gi", "n:gr", "n:K", "n:<C-k>",
  "n:<leader>rn", "n:<leader>ca", "v:<leader>ca",
  "n:<leader>cf", "n:<leader>co",
  "n:<leader>cr", "v:<leader>cr",
  "v:<leader>ce",
  "n:<leader>cq",
  "n:<leader>f",
  "n:<leader>wa", "n:<leader>wr", "n:<leader>wl",
}

for _, k in ipairs(expected_keys) do
  test("LspAttach registers keymap " .. k, function()
    assert_true(key_set[k], "Keymap " .. k .. " was not registered by LspAttach")
  end)
end

test("ruff on_attach disables hoverProvider", function()
  -- fake_client was passed through; the ruff branch sets hoverProvider = false
  assert_eq(fake_client.server_capabilities.hoverProvider, false,
    "ruff LspAttach should disable hoverProvider")
end)

-- Also verify the pylsp on_attach branch mutates capabilities as documented
local pylsp_client = {
  name = "pylsp",
  server_capabilities = {
    hoverProvider = true,
    completionProvider = {},
    definitionProvider = true,
    referencesProvider = true,
    documentHighlightProvider = false,
    documentSymbolProvider = true,
    workspaceSymbolProvider = true,
    signatureHelpProvider = {},
    documentFormattingProvider = true,
    documentRangeFormattingProvider = true,
  },
}
orig_get_client = vim.lsp.get_client_by_id
vim.lsp.get_client_by_id = function(_id) return pylsp_client end
orig_keymap_set = vim.keymap.set
vim.keymap.set = function(_m, _l, _r, _o) end
pcall(attach_cb, fake_args)
vim.keymap.set = orig_keymap_set
vim.lsp.get_client_by_id = orig_get_client

test("pylsp on_attach disables hover/definition/references", function()
  assert_eq(pylsp_client.server_capabilities.hoverProvider, false,
    "pylsp hover should be disabled")
  assert_eq(pylsp_client.server_capabilities.definitionProvider, false,
    "pylsp definition should be disabled")
  assert_eq(pylsp_client.server_capabilities.referencesProvider, false,
    "pylsp references should be disabled")
end)

test("pylsp on_attach disables document/workspace symbols and formatting", function()
  assert_eq(pylsp_client.server_capabilities.documentSymbolProvider, false,
    "pylsp documentSymbolProvider should be disabled")
  assert_eq(pylsp_client.server_capabilities.workspaceSymbolProvider, false,
    "pylsp workspaceSymbolProvider should be disabled")
  assert_eq(pylsp_client.server_capabilities.documentFormattingProvider, false,
    "pylsp formatting should be disabled (ruff LSP handles formatting)")
end)

-- Cleanup
lsp_mock.uninstall()

print("\n=== Test Summary ===")
print(string.format("Passed: %d", results.passed))
print(string.format("Failed: %d", results.failed))
print(string.format("Total: %d", results.passed + results.failed))

if results.failed > 0 then
  print("\nFailed tests:")
  for _, t in ipairs(results.tests) do
    if t.status == "FAIL" then
      print(string.format("  - %s: %s", t.name, t.error))
    end
  end
  vim.cmd("cquit 1")
else
  print("\nAll tests passed!")
  vim.cmd("qall!")
end
