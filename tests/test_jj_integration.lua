-- Test Suite: jj.nvim Integration Tests
-- Tests that require the REAL jj.nvim plugin loaded by lazy.nvim.
-- Run WITHOUT --noplugin flag so lazy.nvim can initialize plugins.
--
-- Usage: nvim --headless -u init.lua -l tests/test_jj_integration.lua
-- (note: no --noplugin flag)

local results = {
  passed = 0,
  failed = 0,
  skipped = 0,
  tests = {}
}

local function test(name, fn)
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

local function skip(name, reason)
  results.skipped = results.skipped + 1
  table.insert(results.tests, {name = name, status = "SKIP", reason = reason})
  print(string.format("⊘ %s: %s", name, reason))
end

local function assert_not_nil(value, msg)
  if value == nil then
    error(msg or "Expected non-nil value")
  end
end

print("\n=== jj.nvim Integration Tests ===\n")

-- Wait for lazy.nvim to finish loading plugins
local jj_available = vim.wait(5000, function()
  return pcall(require, "jj")
end)

-- Check if jj.nvim loaded — skip all tests if not
if not jj_available then
  print("⚠ jj.nvim not available (plugins not loaded). Skipping integration tests.")
  print("  Run without --noplugin flag: nvim --headless -u init.lua -l tests/test_jj_integration.lua")
  print("")
  vim.cmd("qall!")
  return
end

-- Test 1: jj module loads with real plugin
test("jj module loads without errors", function()
  local jj = require("jj")
  assert_not_nil(jj, "jj module should load")
  assert_not_nil(jj.setup, "jj.setup function should exist")
end)

-- Test 2: jj.cmd module loads with real plugin
test("jj.cmd module loads without errors", function()
  local cmd = require("jj.cmd")
  assert_not_nil(cmd, "jj.cmd module should load")
  assert_not_nil(cmd.status, "jj.cmd.status function should exist")
  assert_not_nil(cmd.log, "jj.cmd.log function should exist")
  assert_not_nil(cmd.describe, "jj.cmd.describe function should exist")
  assert_not_nil(cmd.new, "jj.cmd.new function should exist")
  assert_not_nil(cmd.edit, "jj.cmd.edit function should exist")
  assert_not_nil(cmd.diff, "jj.cmd.diff function should exist")
  assert_not_nil(cmd.squash, "jj.cmd.squash function should exist")
end)

-- Test 3: :J command registered by real plugin
test(":J command is registered", function()
  local commands = vim.api.nvim_get_commands({})
  if not commands.J then
    error(":J command not found")
  end
end)

-- Test 4: JJ user commands registered
test("JJ user commands are registered", function()
  local commands = vim.api.nvim_get_commands({})
  local required_commands = {
    "JJStatus", "JJLog", "JJDescribe",
    "JJNew", "JJEdit", "JJDiff", "JJSquash"
  }

  local missing = {}
  for _, cmd in ipairs(required_commands) do
    if not commands[cmd] then
      table.insert(missing, cmd)
    end
  end

  if #missing > 0 then
    error(string.format("Missing commands: %s", table.concat(missing, ", ")))
  end

  print(string.format("  All %d user commands registered", #required_commands))
end)

-- Test 5: jj.nvim configuration is correct
test("jj.nvim configuration is correct", function()
  local cmd = require("jj.cmd")
  if cmd.config.describe_editor ~= "buffer" then
    error(string.format("describe_editor is '%s', expected 'buffer'",
      tostring(cmd.config.describe_editor)))
  end
  print("  describe_editor: buffer ✓")
end)

-- Test 6: Lazy.nvim loaded jj.nvim
test("Lazy.nvim loaded jj.nvim", function()
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    error("Could not load lazy.nvim")
  end

  local plugins = lazy.plugins()
  local found = false
  for _, plugin in pairs(plugins) do
    if plugin.name == "jj.nvim" then
      found = true
      if plugin._.loaded then
        print("  jj.nvim loaded by lazy.nvim ✓")
      else
        error("jj.nvim registered but not loaded")
      end
      break
    end
  end

  if not found then
    error("jj.nvim not found in lazy.nvim plugins")
  end
end)

-- Test 7: Execute jj.cmd.status with real plugin (if in jj repo)
local vcs_ok, vcs = pcall(require, "utils.vcs")
local vcs_type = vcs_ok and vcs.detect_vcs_type() or "none"

if vcs_type == "jj" then
  test("Execute jj.cmd.status (real plugin, jj repo)", function()
    local cmd = require("jj.cmd")
    cmd.status({ notify = true })
  end)
else
  skip("Execute jj.cmd.status", "Not in a jj repository")
end

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Passed: %d", results.passed))
print(string.format("Failed: %d", results.failed))
print(string.format("Skipped: %d", results.skipped))
print(string.format("Total: %d", results.passed + results.failed + results.skipped))

if results.failed > 0 then
  print("\nFailed tests:")
  for _, test_result in ipairs(results.tests) do
    if test_result.status == "FAIL" then
      print(string.format("  - %s: %s", test_result.name, test_result.error))
    end
  end
  vim.cmd("cquit 1")
else
  print("\nAll integration tests passed!")
  vim.cmd("qall!")
end
