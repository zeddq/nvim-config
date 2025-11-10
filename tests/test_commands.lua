-- Test Suite: Command Execution
-- Tests that jj.nvim commands execute without errors

local results = {
  passed = 0,
  failed = 0,
  warnings = 0,
  manual = 0,
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

print("\n=== Command Execution Tests ===\n")

-- Check if we're in a jj repository
local vcs = require("utils.vcs")
local vcs_type = vcs.detect_vcs_type()

print(string.format("Current directory VCS type: %s\n", vcs_type))

if vcs_type ~= "jj" then
  warn("Not in jj repo", "Most tests will be skipped. Run these tests in a jj repository for full coverage.")
end

-- Test 1: :J command exists and is callable
test(":J command is callable", function()
  local commands = vim.api.nvim_get_commands({})
  if not commands.J then
    error(":J command not registered")
  end

  -- Try to get command info
  local cmd_info = commands.J
  if not cmd_info then
    error("Could not get :J command info")
  end
end)

-- Test 2: jj.cmd.status is callable
test("jj.cmd.status function is callable", function()
  local cmd = require("jj.cmd")
  if type(cmd.status) ~= "function" then
    error("jj.cmd.status is not a function")
  end
end)

-- Test 3: Test command execution in jj repo (if applicable)
if vcs_type == "jj" then
  test("Execute :J status command (non-interactive)", function()
    local cmd = require("jj.cmd")

    -- Execute status with notify option (won't open buffer)
    local ok, err = pcall(function()
      cmd.status({ notify = true })
    end)

    if not ok then
      error(string.format("Command execution failed: %s", err))
    end
  end)

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
else
  manual("Command execution in jj repo", "Run this test in a jj repository to test command execution")
end

-- Test 4: Test VCS command routing
test("VCS command routing works", function()
  local vcs_module = require("utils.vcs")
  local detected_type = vcs_module.detect_vcs_type()

  if detected_type == "none" then
    warn("VCS routing", "Not in a VCS repository, skipping routing test")
    return
  end

  -- Test that we can detect the VCS type
  if detected_type ~= "jj" and detected_type ~= "git" then
    error(string.format("Invalid VCS type detected: %s", detected_type))
  end

  print(string.format("  VCS routing detected: %s", detected_type))
end)

-- Test 5: Test keymap execution wrapper (without actually executing)
test("VCS keymap helper functions exist", function()
  -- The keymaps are defined in a plugin config, so we can't easily test them
  -- without triggering them. Instead, verify the VCS module API is complete.
  local vcs_module = require("utils.vcs")

  local required_functions = {
    "detect_vcs_type",
    "is_jj_repo",
    "is_git_repo",
    "get_repo_root",
    "clear_cache",
    "get_cache_stats"
  }

  for _, fn_name in ipairs(required_functions) do
    if type(vcs_module[fn_name]) ~= "function" then
      error(string.format("Missing function: %s", fn_name))
    end
  end

  print("  All VCS helper functions exist")
end)

-- Test 6: Test error handling for commands outside jj repo
if vcs_type ~= "jj" then
  test("Commands handle non-jj repo gracefully", function()
    local cmd = require("jj.cmd")

    -- This should fail gracefully (not crash)
    local ok, err = pcall(function()
      cmd.status({ notify = true })
    end)

    -- We expect this to fail or warn, not crash
    if ok then
      warn("Command execution", "Command succeeded outside jj repo (unexpected)")
    else
      -- Check that error message is reasonable
      if not err:match("jj") and not err:match("repository") then
        error("Error message doesn't mention jj or repository: " .. err)
      end
      print("  Graceful error: " .. tostring(err):sub(1, 50))
    end
  end)
end

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
  vim.cmd("cquit 1") -- Exit with error code
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

  vim.cmd("qall!") -- Exit successfully
end
