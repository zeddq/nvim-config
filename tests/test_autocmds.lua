-- Test Suite: config.autocmds
-- Verifies the UserAutoCommands augroup and its autocmds

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

print("\n=== config.autocmds Tests ===\n")

-- init.lua already required the module; reload to ensure fresh state
package.loaded["config.autocmds"] = nil
require("config.autocmds")

test("UserAutoCommands augroup exists with autocmds", function()
  local autocmds = vim.api.nvim_get_autocmds({ group = "UserAutoCommands" })
  assert_true(#autocmds > 0, "UserAutoCommands group should have at least one autocmd")
  print(string.format("  autocmds registered: %d", #autocmds))
end)

test("Trailing whitespace trimmed on save", function()
  local tmp = vim.fn.tempname()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, tmp)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "foo   ", "bar\t", "baz" })

  -- Write via :write which triggers BufWritePre
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! write! " .. vim.fn.fnameescape(tmp))
  end)

  -- Read back from disk
  local f = io.open(tmp, "r")
  assert_not_nil(f, "temp file should be readable")
  local content = f:read("*a")
  f:close()
  os.remove(tmp)
  vim.api.nvim_buf_delete(buf, { force = true })

  if content:match("[ \t]+\n") or content:match("[ \t]+$") then
    error("Trailing whitespace should have been stripped, got: " .. vim.inspect(content))
  end
end)

test("Python filetype sets shiftwidth and tabstop to 4", function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  -- Setting filetype fires the FileType autocmd via the real event path
  vim.bo[buf].filetype = "python"
  assert_eq(vim.bo[buf].shiftwidth, 4, "python shiftwidth should be 4")
  assert_eq(vim.bo[buf].tabstop, 4, "python tabstop should be 4")
  assert_eq(vim.bo[buf].expandtab, true, "python expandtab should be true")
  vim.api.nvim_buf_delete(buf, { force = true })
end)

test("BufRead on .zshrc sets filetype to zsh", function()
  local tmpdir = vim.fn.tempname()
  vim.fn.mkdir(tmpdir, "p")
  local path = tmpdir .. "/.zshrc"
  local f = io.open(path, "w")
  f:write("# test\n")
  f:close()

  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, path)
  -- Exec BufRead by pattern (not buffer) so the pattern-matched autocmd fires
  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_exec_autocmds("BufRead", {
      group = "UserAutoCommands",
      pattern = ".zshrc",
    })
  end)
  assert_eq(vim.bo[buf].filetype, "zsh", "filetype should be zsh")

  vim.api.nvim_buf_delete(buf, { force = true })
  os.remove(path)
  vim.fn.delete(tmpdir, "d")
end)

test("Help filetype maps 'q' to close buffer-locally", function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = "help"
  local bufmaps = vim.api.nvim_buf_get_keymap(buf, "n")
  local found_q = false
  for _, m in ipairs(bufmaps) do
    if m.lhs == "q" then
      found_q = true
      break
    end
  end
  assert_true(found_q, "buffer-local 'q' mapping should exist on help buffer")
  vim.api.nvim_buf_delete(buf, { force = true })
end)

test("TextYankPost autocmd exists with yank-related desc", function()
  local autocmds = vim.api.nvim_get_autocmds({
    group = "UserAutoCommands",
    event = "TextYankPost",
  })
  assert_true(#autocmds > 0, "at least one TextYankPost autocmd should exist")
  local has_yank_desc = false
  for _, a in ipairs(autocmds) do
    if a.desc and a.desc:lower():find("yank") then
      has_yank_desc = true
      break
    end
  end
  assert_true(has_yank_desc, "TextYankPost autocmd should have desc containing 'yank'")
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
