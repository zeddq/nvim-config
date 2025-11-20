-- Test Suite: VCS Detection
-- Tests the utils.vcs module for correct VCS type detection

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

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s\nExpected: %s\nActual: %s", msg or "Assertion failed", expected, actual))
  end
end

local function assert_not_nil(value, msg)
  if value == nil then
    error(msg or "Expected non-nil value")
  end
end

print("\n=== VCS Detection Tests ===\n")

-- Load the VCS module
local vcs = require("utils.vcs")

-- Test 1: Module loads correctly
test("VCS module loads without errors", function()
  assert_not_nil(vcs.detect_vcs_type, "detect_vcs_type function should exist")
  assert_not_nil(vcs.is_jj_repo, "is_jj_repo function should exist")
  assert_not_nil(vcs.is_git_repo, "is_git_repo function should exist")
  assert_not_nil(vcs.get_repo_root, "get_repo_root function should exist")
  assert_not_nil(vcs.clear_cache, "clear_cache function should exist")
end)

-- Test 2: Detect VCS type in current directory
test("Detect VCS type in current directory", function()
  local vcs_type = vcs.detect_vcs_type()
  assert_not_nil(vcs_type, "VCS type should not be nil")
  -- Should be one of: "jj", "git", or "none"
  local valid = vcs_type == "jj" or vcs_type == "git" or vcs_type == "none"
  if not valid then
    error(string.format("Invalid VCS type: %s", vcs_type))
  end
  print(string.format("  Detected VCS type: %s", vcs_type))
end)

-- Test 3: Cache functionality
test("VCS cache is working", function()
  -- Clear cache first
  vcs.clear_cache()

  -- First call (cache miss)
  local type1 = vcs.detect_vcs_type()

  -- Second call (cache hit)
  local type2 = vcs.get_cached_vcs_type()

  assert_eq(type1, type2, "Cached VCS type should match detected type")
end)

-- Test 4: Cache stats
test("Get cache statistics", function()
  vcs.clear_cache()
  vcs.detect_vcs_type()

  local stats = vcs.get_cache_stats()
  assert_not_nil(stats.total_entries, "Cache stats should have total_entries")
  assert_not_nil(stats.valid_entries, "Cache stats should have valid_entries")
  assert_not_nil(stats.cache_ttl_ms, "Cache stats should have cache_ttl_ms")

  print(string.format("  Cache entries: %d (valid: %d)", stats.total_entries, stats.valid_entries))
end)

-- Test 5: Get repository root
test("Get repository root path", function()
  local vcs_type = vcs.detect_vcs_type()
  if vcs_type ~= "none" then
    local root = vcs.get_repo_root()
    assert_not_nil(root, "Repository root should not be nil in a VCS repo")
    print(string.format("  Root: %s", root))
  else
    print("  Skipped: Not in a VCS repository")
  end
end)

-- Test 6: is_jj_repo function
test("is_jj_repo returns boolean", function()
  local result = vcs.is_jj_repo()
  local is_bool = type(result) == "boolean"
  if not is_bool then
    error(string.format("Expected boolean, got %s", type(result)))
  end
  print(string.format("  is_jj_repo: %s", tostring(result)))
end)

-- Test 7: is_git_repo function
test("is_git_repo returns boolean", function()
  local result = vcs.is_git_repo()
  local is_bool = type(result) == "boolean"
  if not is_bool then
    error(string.format("Expected boolean, got %s", type(result)))
  end
  print(string.format("  is_git_repo: %s", tostring(result)))
end)

-- Test 8: Clear cache functionality
test("Clear cache works correctly", function()
  vcs.detect_vcs_type()
  local before = vcs.get_cache_stats().total_entries

  vcs.clear_cache()
  local after = vcs.get_cache_stats().total_entries

  if after > before then
    error(string.format("Cache not cleared: before=%d, after=%d", before, after))
  end
  print(string.format("  Cache entries before: %d, after: %d", before, after))
end)

-- Test 9: Debug mode toggle
test("Debug mode can be toggled", function()
  local original = vcs.debug
  vcs.debug = true
  assert_eq(vcs.debug, true, "Debug mode should be true")
  vcs.debug = false
  assert_eq(vcs.debug, false, "Debug mode should be false")
  vcs.debug = original -- restore
end)

-- Test 10: Error handling for invalid paths
test("Handles invalid paths gracefully", function()
  local result = vcs.detect_vcs_type("/nonexistent/invalid/path/that/does/not/exist")
  assert_eq(result, "none", "Invalid paths should return 'none'")
end)

-- Print summary
print("\n=== Test Summary ===")
print(string.format("Passed: %d", results.passed))
print(string.format("Failed: %d", results.failed))
print(string.format("Total: %d", results.passed + results.failed))

if results.failed > 0 then
  print("\nFailed tests:")
  for _, test_result in ipairs(results.tests) do
    if test_result.status == "FAIL" then
      print(string.format("  - %s: %s", test_result.name, test_result.error))
    end
  end
  vim.cmd("cquit 1") -- Exit with error code
else
  print("\nAll tests passed!")
  vim.cmd("qall!") -- Exit successfully
end
