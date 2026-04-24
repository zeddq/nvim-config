-- Shared test boilerplate for headless-nvim test suites.
-- Deduplicates the preamble historically copied across test files.

local M = {}

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.uv = vim.uv or vim.loop
package.path = table.concat({
  repo_root .. "/lua/?.lua",
  repo_root .. "/lua/?/init.lua",
  repo_root .. "/tests/?.lua",
  repo_root .. "/tests/?/init.lua",
  package.path,
}, ";")

M.repo_root = repo_root

function M.assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s\nExpected: %s\nActual: %s",
      msg or "Assertion failed", tostring(expected), tostring(actual)), 2)
  end
end

function M.assert_not_nil(v, msg)
  if v == nil then error(msg or "Expected non-nil value", 2) end
end

function M.assert_true(v, msg)
  if not v then error(msg or "Assertion failed: expected truthy value", 2) end
end

local _originals = {}

function M.stub_package(name, mod)
  if _originals[name] == nil then
    _originals[name] = { preload = package.preload[name], loaded = package.loaded[name] }
  end
  package.loaded[name] = nil
  package.preload[name] = function() return mod end
end

function M.restore_package(name)
  local orig = _originals[name]
  if orig == nil then return end
  package.preload[name] = orig.preload
  package.loaded[name] = orig.loaded
  _originals[name] = nil
end

local _tmpdirs = {}

function M.tmpdir()
  local path = vim.fn.tempname()
  vim.fn.mkdir(path, "p")
  table.insert(_tmpdirs, path)
  return path
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    for _, p in ipairs(_tmpdirs) do pcall(vim.fn.delete, p, "rf") end
  end,
})

local Runner = {}
Runner.__index = Runner

function Runner:test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    self.passed = self.passed + 1
    table.insert(self.tests, { name = name, status = "PASS" })
    print(string.format("✓ %s", name))
  else
    self.failed = self.failed + 1
    table.insert(self.tests, { name = name, status = "FAIL", error = tostring(err) })
    print(string.format("✗ %s: %s", name, err))
  end
end

function Runner:warn(name, msg)
  self.warnings = self.warnings + 1
  table.insert(self.tests, { name = name, status = "WARN", error = msg })
  print(string.format("⚠ %s: %s", name, msg or ""))
end

function Runner:skip(name, reason)
  self.skipped = self.skipped + 1
  table.insert(self.tests, { name = name, status = "SKIP", error = reason })
  print(string.format("- %s (skipped: %s)", name, reason or ""))
end

function Runner:manual(name, instr)
  table.insert(self.manual_items, { name = name, instructions = instr })
  print(string.format("[manual] %s: %s", name, instr or ""))
end

function Runner:finish()
  print("\n=== Test Summary ===")
  print(string.format("Passed: %d", self.passed))
  print(string.format("Failed: %d", self.failed))
  print(string.format("Warnings: %d", self.warnings))
  print(string.format("Skipped: %d", self.skipped))
  print(string.format("Total: %d", self.passed + self.failed + self.warnings + self.skipped))
  if self.failed > 0 then
    print("\nFailed tests:")
    for _, t in ipairs(self.tests) do
      if t.status == "FAIL" then print(string.format("  - %s: %s", t.name, t.error)) end
    end
    vim.cmd("cquit 1")
  else
    print("\nAll tests passed!")
    vim.cmd("qall!")
  end
end

function M.new_runner()
  return setmetatable({
    passed = 0, failed = 0, warnings = 0, skipped = 0,
    tests = {}, manual_items = {},
  }, Runner)
end

return M
