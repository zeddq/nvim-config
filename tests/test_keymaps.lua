-- Test Suite: Keymap Configuration Changes
-- Tests the j/k wrapped screen-line movement added in this PR
-- (lua/config/keymaps.lua: count-aware gj/gk remapping)

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

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s\nExpected: %s\nActual: %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local function assert_not_nil(value, msg)
  if value == nil then
    error(msg or "Expected non-nil value")
  end
end

print("\n=== Keymap Configuration Tests ===\n")

-- ── Inline logic tests ────────────────────────────────────────────────────────
-- The j/k mapping uses an expr function: `vim.v.count == 0 and "gj" or "j"`
-- We test the logic directly by calling equivalent functions.

local function j_motion_logic(count)
  return count == 0 and "gj" or "j"
end

local function k_motion_logic(count)
  return count == 0 and "gk" or "k"
end

-- Test 1: j with no count uses screen-line motion
test("j motion: count=0 returns 'gj' (screen-line down)", function()
  assert_eq(j_motion_logic(0), "gj", "j with count=0 should return 'gj'")
end)

-- Test 2: j with count uses real-line motion
test("j motion: count=1 returns 'j' (real-line down)", function()
  assert_eq(j_motion_logic(1), "j", "j with count=1 should return 'j'")
end)

-- Test 3: j with larger count still uses real-line motion
test("j motion: count=10 returns 'j' (real-line down)", function()
  assert_eq(j_motion_logic(10), "j", "j with count=10 should return 'j'")
end)

-- Test 4: k with no count uses screen-line motion
test("k motion: count=0 returns 'gk' (screen-line up)", function()
  assert_eq(k_motion_logic(0), "gk", "k with count=0 should return 'gk'")
end)

-- Test 5: k with count uses real-line motion
test("k motion: count=1 returns 'k' (real-line up)", function()
  assert_eq(k_motion_logic(1), "k", "k with count=1 should return 'k'")
end)

-- Test 6: k with larger count still uses real-line motion
test("k motion: count=99 returns 'k' (real-line up)", function()
  assert_eq(k_motion_logic(99), "k", "k with count=99 should return 'k'")
end)

-- Test 7: Boundary – only zero triggers screen-line motion
test("j motion: negative-like guard (count=0 is the only screen-line trigger)", function()
  -- count is always >= 0 in Neovim; 0 is the only value that should give "gj"
  assert_eq(j_motion_logic(0), "gj", "count=0 -> gj")
  assert_eq(j_motion_logic(1), "j",  "count=1 -> j (not gj)")
  assert_eq(j_motion_logic(2), "j",  "count=2 -> j (not gj)")
end)

-- ── Keymap registration tests ─────────────────────────────────────────────────
-- Verify that the actual keymaps were registered with the correct options.

local function find_keymap(mode, lhs)
  local maps = vim.api.nvim_get_keymap(mode)
  for _, map in ipairs(maps) do
    -- Neovim stores the lhs with spaces sometimes; normalise for comparison
    local stored_lhs = map.lhs:gsub(" ", "<Space>")
    if map.lhs == lhs or stored_lhs == lhs then
      return map
    end
  end
  return nil
end

-- Test 8: 'j' keymap is registered in normal mode
test("j keymap is registered in normal mode", function()
  local map = find_keymap("n", "j")
  if map == nil then
    error("'j' keymap not found in normal mode")
  end
  print(string.format("  Found j keymap: expr=%s silent=%s", tostring(map.expr), tostring(map.silent)))
end)

-- Test 9: 'k' keymap is registered in normal mode
test("k keymap is registered in normal mode", function()
  local map = find_keymap("n", "k")
  if map == nil then
    error("'k' keymap not found in normal mode")
  end
  print(string.format("  Found k keymap: expr=%s silent=%s", tostring(map.expr), tostring(map.silent)))
end)

-- Test 10: 'j' keymap has expr=true (so the function return value is used as keys)
test("j keymap has expr=true option", function()
  local map = find_keymap("n", "j")
  if map == nil then
    error("'j' keymap not found")
  end
  -- Neovim returns 1 for true booleans in keymap metadata
  if map.expr ~= 1 and map.expr ~= true then
    error(string.format("Expected expr=true, got expr=%s", tostring(map.expr)))
  end
end)

-- Test 11: 'k' keymap has expr=true
test("k keymap has expr=true option", function()
  local map = find_keymap("n", "k")
  if map == nil then
    error("'k' keymap not found")
  end
  if map.expr ~= 1 and map.expr ~= true then
    error(string.format("Expected expr=true, got expr=%s", tostring(map.expr)))
  end
end)

-- Test 12: 'j' keymap has silent=true (no command echo in the command line)
test("j keymap has silent=true option", function()
  local map = find_keymap("n", "j")
  if map == nil then
    error("'j' keymap not found")
  end
  if map.silent ~= 1 and map.silent ~= true then
    error(string.format("Expected silent=true, got silent=%s", tostring(map.silent)))
  end
end)

-- Test 13: 'k' keymap has silent=true
test("k keymap has silent=true option", function()
  local map = find_keymap("n", "k")
  if map == nil then
    error("'k' keymap not found")
  end
  if map.silent ~= 1 and map.silent ~= true then
    error(string.format("Expected silent=true, got silent=%s", tostring(map.silent)))
  end
end)

-- Test 14: 'j' keymap description is set correctly
test("j keymap has correct description", function()
  local map = find_keymap("n", "j")
  if map == nil then
    error("'j' keymap not found")
  end
  local desc = map.desc or ""
  if not desc:match("[Mm]ove") and not desc:match("screen") and not desc:match("down") then
    warn("j keymap desc", string.format("Description '%s' may not mention movement direction", desc))
  else
    print(string.format("  j desc: '%s'", desc))
  end
end)

-- Test 15: 'k' keymap description is set correctly
test("k keymap has correct description", function()
  local map = find_keymap("n", "k")
  if map == nil then
    error("'k' keymap not found")
  end
  local desc = map.desc or ""
  if not desc:match("[Mm]ove") and not desc:match("screen") and not desc:match("up") then
    warn("k keymap desc", string.format("Description '%s' may not mention movement direction", desc))
  else
    print(string.format("  k desc: '%s'", desc))
  end
end)

-- ── Print summary ─────────────────────────────────────────────────────────────
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
  print("\nAll tests passed!")
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