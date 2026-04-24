-- Test Suite: utils.lsp
-- Verifies LSP log level toggling and log utility functions

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

local function assert_true(value, msg)
  if not value then
    error(msg or "Expected truthy value")
  end
end

print("\n=== utils.lsp Tests ===\n")

local lsp = require("utils.lsp")
local original_level = vim.lsp.log.get_level()

test("Module exposes expected functions", function()
  assert_eq(type(lsp.toggle_log_level), "function", "toggle_log_level should be a function")
  assert_eq(type(lsp.show_log_level), "function", "show_log_level should be a function")
  assert_eq(type(lsp.open_log), "function", "open_log should be a function")
  assert_eq(type(lsp.tail_log), "function", "tail_log should be a function")
end)

test("toggle_log_level cycles DEBUG -> INFO -> WARN -> DEBUG", function()
  -- Stub vim.notify to silence the informational notifications during the test
  local original_notify = vim.notify
  vim.notify = function(_, _) end

  local ok, err = pcall(function()
    vim.lsp.log.set_level(vim.log.levels.DEBUG)
    assert_eq(vim.lsp.log.get_level(), vim.log.levels.DEBUG, "precondition: DEBUG")

    lsp.toggle_log_level()
    assert_eq(vim.lsp.log.get_level(), vim.log.levels.INFO, "DEBUG -> INFO")

    lsp.toggle_log_level()
    assert_eq(vim.lsp.log.get_level(), vim.log.levels.WARN, "INFO -> WARN")

    lsp.toggle_log_level()
    assert_eq(vim.lsp.log.get_level(), vim.log.levels.DEBUG, "WARN -> DEBUG")
  end)

  vim.notify = original_notify
  if not ok then
    error(err)
  end
end)

test("show_log_level runs without error", function()
  -- Redirect print to suppress output
  local original_print = print
  _G.print = function() end
  local ok, err = pcall(lsp.show_log_level)
  _G.print = original_print
  if not ok then
    error("show_log_level raised: " .. tostring(err))
  end
  assert_true(ok, "show_log_level should not throw")
end)

test("open_log: log filename is non-empty", function()
  -- Don't actually open — just verify the underlying API returns a valid path
  local fname = vim.lsp.log.get_filename()
  assert_not_nil(fname, "log filename should not be nil")
  assert_true(#fname > 0, "log filename should be non-empty")
  assert_eq(type(lsp.open_log), "function", "open_log should remain callable")
end)

-- Restore original log level
pcall(vim.lsp.log.set_level, original_level)

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
