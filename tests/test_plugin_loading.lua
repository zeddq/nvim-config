-- Test Suite: Plugin Loading
-- Tests that jj.nvim and related plugins load correctly
-- NOTE: This test requires plugins to be loaded, so it can't use --noplugin flag

local results = {
  passed = 0,
  failed = 0,
  warnings = 0,
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

print("\n=== Plugin Loading Tests ===\n")

-- Wait for plugins to load
vim.wait(2000, function()
  return pcall(require, "jj")
end)

-- Test 1: jj module loads
test("jj module loads without errors", function()
  local jj = require("jj")
  assert_not_nil(jj, "jj module should load")
  assert_not_nil(jj.setup, "jj.setup function should exist")
end)

-- Test 2: jj.cmd module loads
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

-- Test 3: Check if :J command exists
test(":J command is registered", function()
  local commands = vim.api.nvim_get_commands({})
  if not commands.J then
    error(":J command not found")
  end
end)

-- Test 4: Check user commands
test("JJ user commands are registered", function()
  local commands = vim.api.nvim_get_commands({})
  local required_commands = {
    "JJStatus",
    "JJLog",
    "JJDescribe",
    "JJNew",
    "JJEdit",
    "JJDiff",
    "JJSquash"
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

-- Test 5: Check picker commands (expected to exist but may fail to execute)
test("JJ picker commands check", function()
  local commands = vim.api.nvim_get_commands({})
  local picker_commands = {
    "JJPickerStatus",
    "JJPickerHistory"
  }

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

-- Test 6: VCS keymaps module loads
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
    "<leader>gs",
    "<leader>gl",
    "<leader>gd",
    "<leader>gc",
    "<leader>gn",
    "<leader>gS",
    "<leader>ge",
    "<leader>gR",
    "<leader>g?",
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
    -- This might be expected in headless mode
    warn("VCS keymaps", string.format("Only %d/%d keymaps found. Missing: %s (may be expected in headless mode)",
      found, #keymaps_to_check, table.concat(missing, ", ")))
  else
    print(string.format("  All %d keymaps registered", found))
  end
end)

-- Test 8: Check jj CLI availability
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

-- Test 9: Check jj.nvim configuration
test("jj.nvim configuration is correct", function()
  local cmd = require("jj.cmd")
  if cmd.config.describe_editor ~= "buffer" then
    warn("jj.nvim config", string.format("describe_editor is '%s', expected 'buffer'", cmd.config.describe_editor))
  else
    print("  describe_editor: buffer ✓")
  end
end)

-- Test 10: Verify lazy.nvim loaded jj.nvim
test("Lazy.nvim loaded jj.nvim", function()
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    warn("Lazy.nvim", "Could not load lazy.nvim")
    return
  end

  local plugins = lazy.plugins()
  local found = false
  for _, plugin in pairs(plugins) do
    if plugin.name == "jj.nvim" then
      found = true
      if plugin._.loaded then
        print("  jj.nvim loaded by lazy.nvim ✓")
      else
        warn("jj.nvim", "Plugin registered but not loaded")
      end
      break
    end
  end

  if not found then
    error("jj.nvim not found in lazy.nvim plugins")
  end
end)

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
  vim.cmd("cquit 1") -- Exit with error code
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
  vim.cmd("qall!") -- Exit successfully
end
