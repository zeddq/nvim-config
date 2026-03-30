-- Test Suite: Keymap Configuration (nvim-config)

local results = {
  passed = 0,
  failed = 0,
  tests = {},
}

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    results.passed = results.passed + 1
    table.insert(results.tests, { name = name, status = "PASS" })
    print(string.format("✓ %s", name))
  else
    results.failed = results.failed + 1
    table.insert(results.tests, { name = name, status = "FAIL", error = tostring(err) })
    print(string.format("✗ %s: %s", name, err))
  end
end

local function assert_true(value, msg)
  if not value then
    error(msg or "Assertion failed: expected truthy value")
  end
end

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

-- Compatibility for Neovim 0.9 (vim.loop was renamed to vim.uv in 0.10)
vim.uv = vim.uv or vim.loop

-- Allow requiring local modules without relying on stdpath("config")
package.path = table.concat({
  repo_root .. "/lua/?.lua",
  repo_root .. "/lua/?/init.lua",
  package.path,
}, ";")

-- Stub which-key to avoid plugin dependency when loading keymaps
package.loaded["which-key"] = package.loaded["which-key"] or { show = function() end }

local keymaps_loaded, keymaps_err = pcall(require, "config.keymaps")
if not keymaps_loaded then
  error("Failed to load config.keymaps: " .. tostring(keymaps_err))
end

local function maparg(lhs, mode)
  return vim.fn.maparg(lhs, mode or "n", false, true)
end

print("\n=== Keymap Configuration Tests ===\n")

test("Keymaps module loads without errors", function()
  assert_true(keymaps_loaded, "config.keymaps should load")
end)

test("<leader>w writes the current buffer", function()
  local map = maparg("<leader>w", "n")
  assert_true(map and map.lhs ~= "", "<leader>w mapping should exist")
  assert_true(map.rhs:match(":w"), "mapping should invoke :w")
  assert_true(map.desc and map.desc:match("Save"), "mapping should include save description")
end)

test("Window navigation keymaps (<C-h/j/k/l>) are present", function()
  local keys = { "<C-h>", "<C-j>", "<C-k>", "<C-l>" }
  for _, lhs in ipairs(keys) do
    local map = maparg(lhs, "n")
    assert_true(map and map.rhs ~= "", lhs .. " mapping should exist")
    assert_true(map.rhs:match("<C%-w>"), lhs .. " mapping should use window navigation")
  end
end)

test("<Esc> clears search highlights silently", function()
  local map = maparg("<Esc>", "n")
  assert_true(map and map.rhs ~= "", "<Esc> mapping should exist")
  assert_true(map.rhs:match("nohlsearch"), "mapping should call :nohlsearch")
  assert_true(map.silent == 1 or map.silent == true, "mapping should be silent")
end)

test("Wrapped-line navigation (j/k) uses expr callbacks", function()
  local j_map = maparg("j", "n")
  assert_true(j_map and (j_map.rhs ~= "" or j_map.callback), "j mapping should exist")
  assert_true(j_map.expr == 1 or j_map.expr == true, "j mapping should be expr")
  assert_true(j_map.silent == 1 or j_map.silent == true, "j mapping should be silent")
  assert_true(type(j_map.callback) == "function", "j mapping should use a Lua callback")
  local j_result = j_map.callback()
  assert_true(j_result == "gj", "j mapping should return gj with no count")

  local k_map = maparg("k", "n")
  assert_true(k_map and (k_map.rhs ~= "" or k_map.callback), "k mapping should exist")
  assert_true(k_map.expr == 1 or k_map.expr == true, "k mapping should be expr")
  assert_true(k_map.silent == 1 or k_map.silent == true, "k mapping should be silent")
  assert_true(type(k_map.callback) == "function", "k mapping should use a Lua callback")
  local k_result = k_map.callback()
  assert_true(k_result == "gk", "k mapping should return gk with no count")
end)

-- ── Print summary ─────────────────────────────────────────────────────────────
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
