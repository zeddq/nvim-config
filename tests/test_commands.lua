-- Test Suite: Command Execution (Unit Tests)
-- Tests VCS command routing and wrapper logic using mocks.
-- Does NOT require lazy.nvim to fully initialize external plugins.
--
-- For tests that verify real jj.nvim command execution, see test_jj_integration.lua.

-- Add tests/ to package.path so mocks can be required
local script_dir = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

local jj_mock = require("mocks.jj_mock")

local results = {
  passed = 0,
  failed = 0,
  warnings = 0,
  manual = 0,
  tests = {}
}

local function test(name, fn)
  jj_mock.reset()
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

local function manual(name, instructions)
  results.manual = results.manual + 1
  table.insert(results.tests, {name = name, status = "MANUAL", instructions = instructions})
  print(string.format("⚠ %s: %s", name, instructions))
end

local function warn(name, message)
  results.warnings = results.warnings + 1
  table.insert(results.tests, {name = name, status = "WARN", message = message})
  print(string.format("⚠ %s: %s", name, message))
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

print("\n=== Command Execution Tests (Unit) ===\n")

-- Install mocks
jj_mock.install()

-- Detect VCS type (uses real utils.vcs — not mocked)
local vcs = require("utils.vcs")
local vcs_type = vcs.detect_vcs_type()
print(string.format("Current directory VCS type: %s\n", vcs_type))

-- Test 1: jj.cmd.status is callable via mock
test("jj.cmd.status function is callable", function()
  local cmd = require("jj.cmd")
  assert_eq(type(cmd.status), "function", "jj.cmd.status should be a function")
  cmd.status({ notify = true })
  assert_eq(jj_mock.calls[1].fn, "status", "Should record status call")
end)

-- Test 2: jj.cmd functions dispatch and record arguments
test("jj.cmd functions pass arguments correctly", function()
  local cmd = require("jj.cmd")
  cmd.describe({ message = "test commit" })
  assert_eq(jj_mock.calls[1].fn, "describe", "Should record describe call")
  assert_eq(jj_mock.calls[1].args.message, "test commit", "Should pass message arg")
end)

-- Test 3: All jj.cmd functions are callable
test("All jj.cmd functions execute without error", function()
  local cmd = require("jj.cmd")
  local fns = { "status", "log", "describe", "new", "edit", "diff", "squash" }
  for _, fn_name in ipairs(fns) do
    local ok, err = pcall(cmd[fn_name], {})
    if not ok then
      error(string.format("jj.cmd.%s failed: %s", fn_name, err))
    end
  end
  assert_eq(#jj_mock.calls, #fns, string.format("Should record %d calls", #fns))
end)

-- Test 4: Test jj CLI directly (real, not mocked)
if vcs_type == "jj" then
  test("Test jj CLI directly", function()
    local handle = io.popen("jj st 2>&1")
    if not handle then
      error("Could not execute jj st")
    end

    local result = handle:read("*a")
    local success = handle:close()

    if not success then
      error(string.format("jj st failed: %s", result))
    end

    print(string.format("  jj st output: %s", result:sub(1, 50):gsub("\n", " ")))
  end)
end

-- Test 5: VCS command routing works (real utils.vcs, not mocked)
test("VCS command routing works", function()
  local vcs_module = require("utils.vcs")
  local detected_type = vcs_module.detect_vcs_type()

  if detected_type == "none" then
    warn("VCS routing", "Not in a VCS repository, skipping routing test")
    return
  end

  if detected_type ~= "jj" and detected_type ~= "git" then
    error(string.format("Invalid VCS type detected: %s", detected_type))
  end

  print(string.format("  VCS routing detected: %s", detected_type))
end)

-- Test 6: VCS keymap helper functions exist (real utils.vcs API)
test("VCS keymap helper functions exist", function()
  local vcs_module = require("utils.vcs")
  local required_functions = {
    "detect_vcs_type", "is_jj_repo", "is_git_repo",
    "get_repo_root", "clear_cache", "get_cache_stats"
  }

  for _, fn_name in ipairs(required_functions) do
    if type(vcs_module[fn_name]) ~= "function" then
      error(string.format("Missing function: %s", fn_name))
    end
  end

  print("  All VCS helper functions exist")
end)

-- Cleanup mocks
jj_mock.uninstall()

-- Manual tests (require user interaction)
print("\n=== Manual Tests Required ===")

manual("Test :J status interactive", "Run ':J status' manually and verify output appears in buffer")
manual("Test :JJStatus command", "Run ':JJStatus' manually and verify it works like :J status")
manual("Test :J log command", "Run ':J log' manually and verify log appears in buffer")
manual("Test :J describe command", "Run ':J describe' manually and verify editor opens")
manual("Test <leader>gs keymap", "Press <leader>gs in jj repo and verify status appears")
manual("Test <leader>gl keymap", "Press <leader>gl in jj repo and verify log appears")
manual("Test <leader>gd keymap", "Press <leader>gd in jj repo and verify diff appears")
manual("Test <leader>gn keymap", "Press <leader>gn in jj repo and verify 'jj new' executes")
manual("Test <leader>gR cache clear", "Press <leader>gR and verify notification appears")
manual("Test <leader>g? VCS info", "Press <leader>g? and verify VCS info notification appears")

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Passed: %d", results.passed))
print(string.format("Failed: %d", results.failed))
print(string.format("Warnings: %d", results.warnings))
print(string.format("Manual tests required: %d", results.manual))
print(string.format("Total automated: %d", results.passed + results.failed + results.warnings))

if results.failed > 0 then
  print("\nFailed tests:")
  for _, test_result in ipairs(results.tests) do
    if test_result.status == "FAIL" then
      print(string.format("  - %s: %s", test_result.name, test_result.error))
    end
  end
  vim.cmd("cquit 1")
else
  print("\nAll automated tests passed!")

  if results.warnings > 0 then
    print("\nWarnings:")
    for _, test_result in ipairs(results.tests) do
      if test_result.status == "WARN" then
        print(string.format("  - %s: %s", test_result.name, test_result.message))
      end
    end
  end

  if results.manual > 0 then
    print("\nManual tests to perform:")
    for _, test_result in ipairs(results.tests) do
      if test_result.status == "MANUAL" then
        print(string.format("  - %s", test_result.instructions))
      end
    end
  end

  vim.cmd("qall!")
end
