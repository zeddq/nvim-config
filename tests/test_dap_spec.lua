-- Test Suite: DAP Plugin Spec
-- Loads lua/plugins/dap.lua, stubs dap / dapui / dap-python / osv /
-- nvim-dap-virtual-text, and executes the spec's config function.
-- Asserts adapters + configurations get populated and keymaps are
-- declared via spec.keys.
--
-- Note: the spec uses `keys = { ... }` (lazy.nvim lazy-loads on key press)
-- so the keymaps are registered by lazy.nvim — not installed by config().
-- We verify they appear as keys entries on the spec table.

local script_dir = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

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
  if not cond then error(msg or "Expected truthy") end
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error(string.format("%s: expected %s, got %s", msg or "eq", tostring(b), tostring(a)))
  end
end

print("\n=== DAP Plugin Spec Tests ===\n")

-- ============================================================================
-- Mocks
-- ============================================================================

local function make_dap_mock()
  local mock = {
    adapters = {},
    configurations = { python = {} }, -- pre-populated; dap-python also appends
    listeners = {
      after = { event_initialized = {} },
      before = { event_terminated = {}, event_exited = {} },
    },
  }
  return mock
end

local dap_mock = make_dap_mock()
local dapui_calls = {}
local virtual_text_calls = {}
local dap_python_setup_calls = {}

package.loaded["dap"] = nil
package.loaded["dapui"] = nil
package.loaded["nvim-dap-virtual-text"] = nil
package.loaded["dap-python"] = nil
package.loaded["osv"] = nil

package.preload["dap"] = function() return dap_mock end
package.preload["dapui"] = function()
  return {
    setup = function(opts) table.insert(dapui_calls, opts) end,
    open = function() end,
    close = function() end,
    toggle = function() end,
  }
end
package.preload["nvim-dap-virtual-text"] = function()
  return { setup = function(opts) table.insert(virtual_text_calls, opts) end }
end
package.preload["dap-python"] = function()
  return {
    setup = function(py) table.insert(dap_python_setup_calls, py) end,
    test_method = function() end,
  }
end
package.preload["osv"] = function()
  return {
    launch = function() end,
    run_this = function() end,
  }
end

-- ============================================================================
-- Helper: run the spec's config() with a specified bash-debug-adapter
-- availability. Returns the dap_mock state after execution.
-- ============================================================================

local function run_dap_config(bash_available)
  -- Fresh dap mock for isolated branch testing
  dap_mock = make_dap_mock()
  package.loaded["dap"] = nil
  package.preload["dap"] = function() return dap_mock end

  package.loaded["plugins.dap"] = nil
  local spec = require("plugins.dap")
  assert(type(spec) == "table", "plugins.dap must return a table")
  local entry = spec[1]
  assert(entry[1] == "mfussenegger/nvim-dap", "Expected first spec entry = nvim-dap")

  -- Override vim.fn.executable to force bash-debug-adapter presence/absence
  local orig_executable = vim.fn.executable
  vim.fn.executable = function(path)
    if type(path) == "string" and path:find("bash%-debug%-adapter") then
      return bash_available and 1 or 0
    end
    return orig_executable(path)
  end

  -- Stub sign_define to avoid polluting signs
  local orig_sign_define = vim.fn.sign_define
  vim.fn.sign_define = function(_n, _o) end

  -- Stub create_user_command (osv commands)
  local orig_create_user_cmd = vim.api.nvim_create_user_command
  vim.api.nvim_create_user_command = function(_n, _c, _o) end

  local ok, err = pcall(entry.config, entry, entry.opts or {})

  vim.fn.executable = orig_executable
  vim.fn.sign_define = orig_sign_define
  vim.api.nvim_create_user_command = orig_create_user_cmd

  return ok, err, spec, entry
end

-- ============================================================================
-- Plugin-table shape assertions
-- ============================================================================

package.loaded["plugins.dap"] = nil
local spec_initial = require("plugins.dap")

test("plugins.dap returns table with nvim-dap as first entry", function()
  assert_true(type(spec_initial) == "table", "spec must be table")
  local entry = spec_initial[1]
  assert_eq(entry[1], "mfussenegger/nvim-dap", "First entry must be nvim-dap")
end)

test("nvim-dap spec lists dap-ui and dap-python as dependencies", function()
  local entry = spec_initial[1]
  local deps = entry.dependencies or {}
  local dep_set = {}
  for _, d in ipairs(deps) do dep_set[d] = true end
  assert_true(dep_set["rcarriga/nvim-dap-ui"], "rcarriga/nvim-dap-ui must be in dependencies")
  assert_true(dep_set["mfussenegger/nvim-dap-python"], "mfussenegger/nvim-dap-python must be in dependencies")
end)

-- ============================================================================
-- Branch 1: bash-debug-adapter NOT available
-- ============================================================================

local ok1, err1, _spec1 = run_dap_config(false)
test("config() runs when bash-debug-adapter is unavailable", function()
  if not ok1 then error("config() failed: " .. tostring(err1)) end
end)

test("dap.adapters.nlua is registered", function()
  assert_true(type(dap_mock.adapters.nlua) == "function",
    "dap.adapters.nlua should be a function (server-type adapter callback)")
end)

test("dap.adapters.bashdb is NOT set when bash-debug-adapter is missing", function()
  assert_eq(dap_mock.adapters.bashdb, nil,
    "bashdb adapter must be absent when bash-debug-adapter executable is missing")
end)

test("dap.configurations.sh/bash/zsh are NOT set when bash adapter is missing", function()
  assert_eq(dap_mock.configurations.sh, nil, "configurations.sh should be nil")
  assert_eq(dap_mock.configurations.bash, nil, "configurations.bash should be nil")
  assert_eq(dap_mock.configurations.zsh, nil, "configurations.zsh should be nil")
end)

test("dap-python.setup was called", function()
  assert_true(#dap_python_setup_calls >= 1, "dap-python.setup should be invoked")
end)

test("dap.configurations.python is populated", function()
  assert_true(type(dap_mock.configurations.python) == "table"
    and #dap_mock.configurations.python >= 1, "python configuration should be populated")
  -- The spec inserts a 'Launch file with arguments' entry
  local has_args_entry = false
  for _, c in ipairs(dap_mock.configurations.python) do
    if c.name == "Launch file with arguments" then has_args_entry = true end
  end
  assert_true(has_args_entry, "Expected 'Launch file with arguments' python config")
end)

-- ============================================================================
-- Branch 2: bash-debug-adapter IS available
-- ============================================================================

local ok2, err2, _spec2 = run_dap_config(true)
test("config() runs when bash-debug-adapter is available", function()
  if not ok2 then error("config() failed: " .. tostring(err2)) end
end)

test("dap.adapters.bashdb is set when bash-debug-adapter is present", function()
  assert_true(dap_mock.adapters.bashdb ~= nil, "bashdb adapter should be set")
  assert_eq(dap_mock.adapters.bashdb.type, "executable", "bashdb adapter type must be executable")
  assert_eq(dap_mock.adapters.bashdb.name, "bashdb", "bashdb adapter name must be 'bashdb'")
end)

test("dap.configurations.sh/bash/zsh are populated when bash adapter is present", function()
  assert_true(type(dap_mock.configurations.sh) == "table" and #dap_mock.configurations.sh > 0,
    "configurations.sh should be populated")
  assert_true(type(dap_mock.configurations.bash) == "table" and #dap_mock.configurations.bash > 0,
    "configurations.bash should be populated")
  assert_true(type(dap_mock.configurations.zsh) == "table" and #dap_mock.configurations.zsh > 0,
    "configurations.zsh should be populated")
end)

test("sh configuration uses bashdb adapter type", function()
  local cfg = dap_mock.configurations.sh[1]
  assert_eq(cfg.type, "bashdb", "sh config should use 'bashdb' type")
  assert_eq(cfg.request, "launch", "sh config should be launch request")
end)

-- ============================================================================
-- DAP keymaps (spec.keys entries)
-- ============================================================================

local entry = spec_initial[1]
local keys = entry.keys or {}
local key_set = {}
for _, k in ipairs(keys) do
  local lhs = k[1]
  if lhs then key_set[lhs] = true end
end

local expected_keys = {
  "<F5>", "<F10>", "<F11>", "<F12>",
  "<leader>b", "<leader>B",
  "<leader>dr", "<leader>dl", "<leader>du",
}

for _, k in ipairs(expected_keys) do
  test("DAP spec declares keymap " .. k, function()
    assert_true(key_set[k], "Key " .. k .. " missing from spec.keys; have: "
      .. table.concat(vim.tbl_keys(key_set), ", "))
  end)
end

test("dap-ui was configured", function()
  assert_true(#dapui_calls >= 1, "dapui.setup should be called")
end)

test("nvim-dap-virtual-text was configured", function()
  assert_true(#virtual_text_calls >= 1, "virtual-text setup should be called")
end)

-- ============================================================================
-- Cleanup
-- ============================================================================

package.preload["dap"] = nil
package.preload["dapui"] = nil
package.preload["nvim-dap-virtual-text"] = nil
package.preload["dap-python"] = nil
package.preload["osv"] = nil
package.loaded["dap"] = nil
package.loaded["dapui"] = nil
package.loaded["nvim-dap-virtual-text"] = nil
package.loaded["dap-python"] = nil
package.loaded["osv"] = nil
package.loaded["plugins.dap"] = nil

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
