-- Test Suite: config.options
-- Verifies editor options, leader keys, providers, and clipboard

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
    error(string.format("%s\nExpected: %s\nActual: %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local function assert_not_nil(value, msg)
  if value == nil then
    error(msg or "Expected non-nil value")
  end
end

print("\n=== config.options Tests ===\n")

-- `nvim --headless -l` forces updatetime=1 as a headless optimization, overriding
-- what config.options set during init. Re-run the module after require cache is cleared
-- to restore the intended values for this test process.
package.loaded["config.options"] = nil
require("config.options")

test("Line numbers enabled", function()
  assert_eq(vim.o.number, true, "number should be true")
  assert_eq(vim.o.relativenumber, true, "relativenumber should be true")
end)

test("Indentation: expandtab/tabstop/shiftwidth", function()
  assert_eq(vim.o.expandtab, true, "expandtab should be true")
  assert_eq(vim.o.tabstop, 4, "tabstop should be 4")
  assert_eq(vim.o.shiftwidth, 4, "shiftwidth should be 4")
end)

test("Search: ignorecase + smartcase", function()
  assert_eq(vim.o.ignorecase, true, "ignorecase should be true")
  assert_eq(vim.o.smartcase, true, "smartcase should be true")
end)

test("UI: termguicolors enabled", function()
  assert_eq(vim.o.termguicolors, true, "termguicolors should be true")
end)

test("Persistent undo enabled", function()
  assert_eq(vim.o.undofile, true, "undofile should be true")
end)

test("Performance: updatetime + timeoutlen", function()
  assert_eq(vim.o.updatetime, 250, "updatetime should be 250")
  assert_eq(vim.o.timeoutlen, 300, "timeoutlen should be 300")
end)

test("Splits: splitbelow + splitright", function()
  assert_eq(vim.o.splitbelow, true, "splitbelow should be true")
  assert_eq(vim.o.splitright, true, "splitright should be true")
end)

test("Completion: completeopt", function()
  assert_eq(vim.o.completeopt, "menu,menuone,noselect", "completeopt mismatch")
end)

test("Leader keys configured", function()
  assert_eq(vim.g.mapleader, " ", "mapleader should be space")
  assert_eq(vim.g.maplocalleader, "\\", "maplocalleader should be backslash")
end)

test("Unused providers disabled", function()
  assert_eq(vim.g.loaded_perl_provider, 0, "perl provider should be 0")
  assert_eq(vim.g.loaded_ruby_provider, 0, "ruby provider should be 0")
  assert_eq(vim.g.loaded_node_provider, 0, "node provider should be 0")
end)

test("Clipboard includes unnamedplus", function()
  assert_not_nil(vim.o.clipboard:find("unnamedplus"), "clipboard should include unnamedplus")
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
  vim.cmd("cquit 1")
else
  print("\nAll tests passed!")
  vim.cmd("qall!")
end
