-- Test Suite: Configuration Regression Checks (nvim-config)

local results = {
  passed = 0,
  failed = 0,
  warnings = 0,
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

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s\nExpected: %s\nActual: %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

-- Compatibility for Neovim 0.9 (vim.loop renamed to vim.uv)
vim.uv = vim.uv or vim.loop

-- Make local lua modules discoverable without relying on stdpath("config")
package.path = table.concat({
  repo_root .. "/lua/?.lua",
  repo_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function read_file(relpath)
  return table.concat(vim.fn.readfile(repo_root .. "/" .. relpath), "\n")
end

local function list_contains(tbl, needle)
  for _, value in ipairs(tbl or {}) do
    if value == needle then
      return true
    end
  end
  return false
end

print("\n=== Configuration Regression Tests ===\n")

test("DAP spec declares core plugin and required dependencies", function()
  local dap_spec = require("plugins.dap")[1]
  assert_eq(dap_spec[1], "mfussenegger/nvim-dap", "First entry should be nvim-dap")

  local deps = dap_spec.dependencies or {}
  assert_true(list_contains(deps, "rcarriga/nvim-dap-ui"), "dap-ui dependency should be present")
  assert_true(list_contains(deps, "mfussenegger/nvim-dap-python"), "dap-python dependency should be present")
end)

test("DAP config guards bash adapter setup and keeps expected paths", function()
  local content = read_file("lua/plugins/dap.lua")
  assert_true(content:match("mason%-registry"), "bash adapter should be gated by mason-registry availability")
  assert_true(content:match("bash%-debug%-adapter"), "bash-debug-adapter references should remain")
  assert_true(content:match("/opt/homebrew/bin/bash"), "Homebrew bash path should be present")
  assert_true(content:match("/bin/bash"), "System bash fallback should be present")
  assert_true(content:match("configurations%.sh") and content:match("configurations%.zsh"), "sh and zsh configurations should be assigned")
end)

test("Treesitter config keeps expected language set", function()
  local treesitter_spec = require("plugins.treesitter")[1]
  local captured
  package.loaded["nvim-treesitter.configs"] = {
    setup = function(opts)
      captured = opts
    end,
  }

  treesitter_spec.config()

  assert_true(type(captured) == "table", "Treesitter config should call setup")
  local ensure = captured.ensure_installed or {}
  local expected = { "python", "lua", "vim", "vimdoc", "query" }
  for _, lang in ipairs(expected) do
    assert_true(vim.tbl_contains(ensure, lang), "ensure_installed should include " .. lang)
  end
  assert_eq(captured.auto_install, true, "auto_install should be enabled")
end)

test("JJ plugin keeps documented diff keymaps", function()
  local jj_spec = require("plugins.jj")
  assert_eq(jj_spec[1], "nicolasgb/jj.nvim", "jj plugin spec should target nicolasgb/jj.nvim")
  assert_true(list_contains(jj_spec.dependencies or {}, "folke/snacks.nvim"), "jj plugin should depend on snacks.nvim")

  local content = read_file("lua/plugins/jj.lua")
  assert_true(content:match("<leader>df"), "diff keymap <leader>df should remain defined")
  assert_true(content:match("<leader>dF"), "diff keymap <leader>dF should remain defined")
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
  print("\nAll critical tests passed!")
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
