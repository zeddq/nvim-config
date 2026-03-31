-- Test Suite: Plugin Loading (Unit Tests)
-- Tests plugin configuration, keymaps, and wrapper logic using mocks.
-- Does NOT require lazy.nvim to fully initialize external plugins.
--
-- For tests that verify real jj.nvim plugin loading, see test_jj_integration.lua.

-- Add tests/ to package.path so mocks can be required
local script_dir = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

local jj_mock = require("mocks.jj_mock")

local results = {
  passed = 0,
  failed = 0,
  warnings = 0,
  tests = {}
}

local function test(name, fn)
  jj_mock.reset() -- Clean call log between tests
  local ok, err = pcall(fn)
  if ok then
    results.passed = results.passed + 1
    table.insert(results.tests, {name = name, status = "PASS"})
    print(string.format("✓ %s", name))
  else
    results.failed = results.failed + 1
    table.insert(results.tests, {name = name, status = "FAIL", error = tostring(err)})
    print(string.format("✗ %s: %s", name, err))
  end
end

local function warn(name, message)
  results.warnings = results.warnings + 1
  table.insert(results.tests, {name = name, status = "WARN", message = message})
  print(string.format("⚠ %s: %s", name, message))
end

local function assert_not_nil(value, msg)
  if value == nil then
    error(msg or "Expected non-nil value")
  end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

print("\n=== Plugin Loading Tests (Unit) ===\n")

-- Install mocks before running tests
jj_mock.install()

-- Test 1: Mock jj module provides expected API surface
test("jj mock provides setup function", function()
  local jj = require("jj")
  assert_not_nil(jj, "jj module should load")
  assert_not_nil(jj.setup, "jj.setup function should exist")
end)

-- Test 2: Mock jj.cmd provides all expected functions
test("jj.cmd mock provides complete API", function()
  local cmd = require("jj.cmd")
  assert_not_nil(cmd, "jj.cmd module should load")
  local required_fns = { "status", "log", "describe", "new", "edit", "diff", "squash" }
  for _, fn_name in ipairs(required_fns) do
    assert_eq(type(cmd[fn_name]), "function",
      string.format("jj.cmd.%s should be a function", fn_name))
  end
end)

-- Test 3: jj.cmd functions are callable and record calls
test("jj.cmd wrapper calls dispatch correctly", function()
  local cmd = require("jj.cmd")
  cmd.status({ notify = true })
  cmd.log({})

  assert_eq(#jj_mock.calls, 2, "Should record 2 calls")
  assert_eq(jj_mock.calls[1].fn, "status", "First call should be status")
  assert_eq(jj_mock.calls[2].fn, "log", "Second call should be log")
end)

-- Test 4: jj.cmd.config is accessible (structure check, not value check — values tested in integration)
test("jj.cmd configuration is accessible", function()
  local cmd = require("jj.cmd")
  assert_not_nil(cmd.config, "config table should exist")
  assert_not_nil(cmd.config.describe_editor, "describe_editor should be set")
end)

-- Test 5: Picker commands check (expected to be absent in headless)
test("JJ picker commands check", function()
  local commands = vim.api.nvim_get_commands({})
  local picker_commands = { "JJPickerStatus", "JJPickerHistory" }

  local found = 0
  for _, cmd in ipairs(picker_commands) do
    if commands[cmd] then
      found = found + 1
    end
  end

  if found == 0 then
    warn("Picker commands", "No picker commands found (expected if picker disabled)")
  else
    print(string.format("  Found %d/%d picker commands", found, #picker_commands))
  end
end)

-- Test 6: VCS keymaps module configuration file exists
test("VCS keymaps module configuration exists", function()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/vcs-keymaps.lua"
  local exists = vim.fn.filereadable(config_path) == 1
  if not exists then
    error("vcs-keymaps.lua not found")
  end
end)

-- Test 7: Check if keymaps are registered
test("VCS keymaps are registered", function()
  local keymaps_to_check = {
    "<leader>gs", "<leader>gl", "<leader>gd", "<leader>gc",
    "<leader>gn", "<leader>gS", "<leader>ge", "<leader>gR", "<leader>g?",
  }

  local found = 0
  local missing = {}

  for _, lhs in ipairs(keymaps_to_check) do
    local maps = vim.api.nvim_get_keymap("n")
    local found_map = false
    for _, map in ipairs(maps) do
      if map.lhs == lhs or map.lhs:gsub("%s+", "") == lhs:gsub("%s+", "") then
        found_map = true
        break
      end
    end
    if found_map then
      found = found + 1
    else
      table.insert(missing, lhs)
    end
  end

  if found < #keymaps_to_check then
    warn("VCS keymaps", string.format("Only %d/%d keymaps found. Missing: %s (may be expected in headless mode)",
      found, #keymaps_to_check, table.concat(missing, ", ")))
  else
    print(string.format("  All %d keymaps registered", found))
  end
end)

-- Test 8: jj CLI availability
test("jj CLI is available", function()
  local handle = io.popen("which jj 2>/dev/null")
  if not handle then
    error("Cannot check for jj CLI")
  end

  local result = handle:read("*a")
  handle:close()

  if result == "" then
    warn("jj CLI", "jj command not found in PATH - commands will fail")
  else
    print(string.format("  jj found at: %s", result:gsub("\n", "")))
  end
end)

-- Test 9: Utils modules load without errors
test("utils.vcs module loads", function()
  local vcs = require("utils.vcs")
  assert_not_nil(vcs, "utils.vcs should load")
  assert_not_nil(vcs.detect_vcs_type, "detect_vcs_type should exist")
end)

-- Test 10: Utils.lsp module loads without errors
test("utils.lsp module loads", function()
  local lsp_utils = require("utils.lsp")
  assert_not_nil(lsp_utils, "utils.lsp should load")
end)

-- Cleanup mocks
jj_mock.uninstall()

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Passed: %d", results.passed))
print(string.format("Failed: %d", results.failed))
print(string.format("Warnings: %d", results.warnings))
print(string.format("Total: %d", results.passed + results.failed + results.warnings))

if results.failed > 0 then
  print("\nFailed tests:")
  for _, test_result in ipairs(results.tests) do
    if test_result.status == "FAIL" then
      print(string.format("  - %s: %s", test_result.name, test_result.error))
    end
  end
  vim.cmd("cquit 1")
else
  print("\nAll critical tests passed!")
  if results.warnings > 0 then
    print("\nWarnings (non-critical):")
    for _, test_result in ipairs(results.tests) do
      if test_result.status == "WARN" then
        print(string.format("  - %s: %s", test_result.name, test_result.message))
      end
    end
  end
  vim.cmd("qall!")
end
