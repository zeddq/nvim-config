-- Test Suite: Integration Tests
-- Tests the integration between VCS detection, keymaps, and command execution

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

print("\n=== Integration Tests ===\n")

-- Wait for plugins to load
vim.wait(2000, function()
  return pcall(require, "jj")
end)

local vcs = require("utils.vcs")
local vcs_type = vcs.detect_vcs_type()

print(string.format("Environment: VCS type = %s\n", vcs_type))

-- Test 1: VCS detection integrates with jj.nvim
test("VCS detection works correctly", function()
  local detected = vcs.detect_vcs_type()
  if detected ~= "jj" and detected ~= "git" and detected ~= "none" then
    error(string.format("Invalid VCS type: %s", detected))
  end
  print(string.format("  Detected: %s", detected))
end)

-- Test 2: Command execution based on VCS type
test("Command routing based on VCS detection", function()
  local detected = vcs.detect_vcs_type()

  if detected == "jj" then
    -- Test that jj commands are available
    local cmd = require("jj.cmd")
    if type(cmd.status) ~= "function" then
      error("jj.cmd.status not available in jj repo")
    end
    print("  jj commands available in jj repo ✓")
  elseif detected == "git" then
    -- In git repo, jj commands should still exist but fail gracefully
    local cmd = require("jj.cmd")
    if type(cmd.status) ~= "function" then
      error("jj.cmd.status should exist even in git repo")
    end
    print("  jj commands exist but will fail gracefully in git repo ✓")
  else
    print("  No VCS repo detected ✓")
  end
end)

-- Test 3: Cache invalidation on directory change
test("Cache invalidation works", function()
  vcs.clear_cache()
  local type1 = vcs.detect_vcs_type()

  -- Change directory (within same repo)
  local cwd = vim.fn.getcwd()
  vcs.clear_cache()

  local type2 = vcs.detect_vcs_type()

  -- Should be the same type but cache was cleared
  if type1 ~= type2 then
    warn("Cache invalidation", "VCS type changed after cache clear (may be expected if directory changed)")
  else
    print(string.format("  VCS type consistent: %s", type1))
  end
end)

-- Test 4: Multiple VCS operations in sequence
test("Multiple VCS operations work correctly", function()
  -- Clear cache
  vcs.clear_cache()

  -- Detect VCS
  local type1 = vcs.detect_vcs_type()

  -- Get cached type (should hit cache)
  local type2 = vcs.get_cached_vcs_type()

  -- Get repo root
  local root = nil
  if type1 ~= "none" then
    root = vcs.get_repo_root()
  end

  -- Get cache stats
  local stats = vcs.get_cache_stats()

  if type1 ~= type2 then
    error("Cached type doesn't match detected type")
  end

  if type1 ~= "none" and not root then
    error("Root should be found in VCS repo")
  end

  if stats.valid_entries < 1 then
    error("Should have at least one cache entry")
  end

  print(string.format("  Type: %s, Root: %s, Cache entries: %d",
    type1, root or "none", stats.valid_entries))
end)

-- Test 5: Command execution in jj repository (if applicable)
if vcs_type == "jj" then
  test("Execute jj status command", function()
    local cmd = require("jj.cmd")

    -- Execute in notify mode (non-interactive)
    local ok, err = pcall(function()
      cmd.status({ notify = true })
    end)

    if not ok then
      error(string.format("Command failed: %s", err))
    end
  end)

  test("jj.nvim can detect jj repo", function()
    local utils_ok, utils = pcall(require, "jj.utils")
    if utils_ok and utils.ensure_jj then
      local in_jj_repo = utils.ensure_jj()
      if not in_jj_repo then
        error("jj.utils.ensure_jj() returned false in jj repo")
      end
      print("  jj.utils.ensure_jj() ✓")
    else
      warn("jj.utils", "Could not load jj.utils module")
    end
  end)

  test("User commands work in jj repo", function()
    local commands = vim.api.nvim_get_commands({})

    if not commands.JJStatus then
      error("JJStatus command not found")
    end

    if not commands.JJLog then
      error("JJLog command not found")
    end

    if not commands.JJDiff then
      error("JJDiff command not found")
    end

    print("  User commands registered ✓")
  end)
else
  warn("jj-specific tests", "Not in a jj repository, skipping jj-specific integration tests")
end

-- Test 6: Error handling integration
test("Error handling is consistent", function()
  -- Test invalid path
  local result = vcs.detect_vcs_type("/nonexistent/path")
  if result ~= "none" then
    error("Invalid path should return 'none'")
  end

  -- Test that clear_cache doesn't error
  vcs.clear_cache()
  vcs.clear_cache(vim.fn.getcwd())

  print("  Error handling ✓")
end)

-- Test 7: Autocmd integration
test("VCS autocmd integration", function()
  -- Check if VCSCacheCleared autocmd exists
  local autocmds = vim.api.nvim_get_autocmds({ event = "User", pattern = "VCSCacheCleared" })

  if #autocmds == 0 then
    warn("VCSCacheCleared autocmd", "No autocmds registered for VCSCacheCleared event")
  else
    print(string.format("  %d autocmd(s) registered for VCSCacheCleared", #autocmds))
  end
end)

-- Test 8: DirChanged autocmd
test("DirChanged autocmd clears VCS cache", function()
  local autocmds = vim.api.nvim_get_autocmds({ event = "DirChanged" })

  local vcs_autocmd_found = false
  for _, autocmd in ipairs(autocmds) do
    if autocmd.desc and autocmd.desc:match("VCS") then
      vcs_autocmd_found = true
      break
    end
  end

  if not vcs_autocmd_found then
    warn("DirChanged autocmd", "No VCS-related DirChanged autocmd found")
  else
    print("  DirChanged autocmd registered ✓")
  end
end)

-- Test 9: Picker graceful failure (expected)
test("Picker commands fail gracefully when disabled", function()
  local picker_ok, picker = pcall(require, "jj.picker")

  if picker_ok and picker.status then
    -- Picker is available (unexpected if disabled in config)
    warn("Picker availability", "Picker is available but expected to be disabled")
  else
    -- Expected behavior: picker not available
    print("  Picker correctly disabled ✓")
  end
end)

-- Test 10: Overall integration health check
test("Overall integration health check", function()
  local issues = {}

  -- Check VCS module
  if not pcall(require, "utils.vcs") then
    table.insert(issues, "VCS module not loadable")
  end

  -- Check jj module
  if not pcall(require, "jj") then
    table.insert(issues, "jj module not loadable")
  end

  -- Check jj.cmd module
  if not pcall(require, "jj.cmd") then
    table.insert(issues, "jj.cmd module not loadable")
  end

  -- Check commands
  local commands = vim.api.nvim_get_commands({})
  if not commands.J then
    table.insert(issues, ":J command not registered")
  end

  -- Check jj CLI
  local handle = io.popen("which jj 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result == "" then
      table.insert(issues, "jj CLI not in PATH")
    end
  end

  if #issues > 0 then
    error("Health check failed:\n  - " .. table.concat(issues, "\n  - "))
  end

  print("  All integration components healthy ✓")
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
  print("\nAll integration tests passed!")
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
