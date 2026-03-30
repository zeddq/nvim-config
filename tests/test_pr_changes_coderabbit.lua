-- Test Suite: Configuration Regression Checks (nvim-config)

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
  assert_true(
    content:match("vim%.fn%.executable%(bash_debug_adapter_bin%)"),
    "bash adapter should be gated by vim.fn.executable(bash_debug_adapter_bin)"
  )
  assert_true(content:match("bash%-debug%-adapter"), "bash-debug-adapter references should remain")
  assert_true(
    content:match("cwd%s*=%s*function%(%s*%)%s*return%s+vim%.fn%.getcwd%(%s*%)%s*end"),
    "bash DAP cwd should be resolved at launch time via function"
  )
  assert_true(content:match("/opt/homebrew/bin/bash"), "Homebrew bash path should be present")
  assert_true(content:match("/bin/bash"), "System bash fallback should be present")
  assert_true(
    content:match("configurations%.sh") and content:match("configurations%.bash") and content:match("configurations%.zsh"),
    "sh, bash, and zsh configurations should be assigned"
  )
end)

test("Treesitter config keeps expected language set", function()
  local treesitter_spec = require("plugins.treesitter")[1]
  local captured
  local registered = {}

  -- Save originals before stubbing
  local orig_ts_configs = package.loaded["nvim-treesitter.configs"]
  local orig_register = vim.treesitter.language.register

  package.loaded["nvim-treesitter.configs"] = {
    setup = function(opts)
      captured = opts
    end,
  }
  vim.treesitter.language.register = function(parser, lang)
    registered[lang] = parser
  end

  local ok, err = pcall(treesitter_spec.config)

  -- Restore originals (even on failure)
  package.loaded["nvim-treesitter.configs"] = orig_ts_configs
  vim.treesitter.language.register = orig_register

  if not ok then error(err) end

  assert_true(type(captured) == "table", "Treesitter config should call setup")
  local ensure = captured.ensure_installed or {}
  local expected = { "bash", "python", "lua", "vim", "vimdoc", "query" }
  for _, lang in ipairs(expected) do
    assert_true(vim.tbl_contains(ensure, lang), "ensure_installed should include " .. lang)
  end
  assert_eq(captured.auto_install, true, "auto_install should be enabled")
  assert_eq(registered["zsh"], "bash", "zsh should be registered as bash parser alias")
end)

test("JJ plugin keeps documented diff keymaps", function()
  local jj_spec = require("plugins.jj")
  assert_eq(jj_spec[1], "nicolasgb/jj.nvim", "jj plugin spec should target nicolasgb/jj.nvim")
  assert_true(list_contains(jj_spec.dependencies or {}, "folke/snacks.nvim"), "jj plugin should depend on snacks.nvim")

  local content = read_file("lua/plugins/jj.lua")
  -- Unconditional diff keymaps (always registered via jj.diff module)
  assert_true(content:match("<leader>df"), "diff keymap <leader>df should remain defined")
  assert_true(content:match("<leader>dF"), "diff keymap <leader>dF should remain defined")
  -- Unconditional cmd.diff keymaps (revision view)
  assert_true(content:match("<leader>dd"), "diff keymap <leader>dd should remain defined")
  assert_true(content:match("<leader>dD"), "diff keymap <leader>dD should remain defined")
  -- Conditional cezdiff keymaps (guarded by cmd.cezdiff nil check)
  assert_true(content:match("if%s+cmd%.cezdiff%s+then"), "cezdiff keymaps should stay guarded by cmd.cezdiff availability")
  assert_true(content:match("<leader>dj"), "diff keymap <leader>dj should remain defined (cezdiff, terminal)")
  assert_true(content:match("<leader>dJ"), "diff keymap <leader>dJ should remain defined (cezdiff current, terminal)")
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
  print("\nAll critical tests passed!")
  vim.cmd("qall!")
end
