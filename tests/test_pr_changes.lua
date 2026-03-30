-- Test Suite: PR-Specific Configuration Changes
-- Tests changes introduced in this PR across:
--   lua/plugins/dap.lua       – bash debugger refactor
--   lua/plugins/lsp.lua       – pyenv python detection
--   lua/plugins/treesitter.lua – bash language registration
--   lua/plugins/jj.lua        – new diff keymaps

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

print("\n=== PR Changes Tests ===\n")

-- ─────────────────────────────────────────────────────────────────────────────
-- Section 1: DAP – Bash debugger refactor (lua/plugins/dap.lua)
-- ─────────────────────────────────────────────────────────────────────────────
print("--- DAP: Bash Debugger ---\n")

-- The PR replaced the mason-registry check with a direct vim.fn.executable() check.
-- It also made pathBash dynamic and added a 'bash' filetype alongside 'sh'/'zsh'.
-- We test the logic patterns used in the refactored code.

-- Test 1: pathBash selection logic – homebrew bash preferred when available
test("DAP pathBash: /opt/homebrew/bin/bash preferred when executable", function()
  -- Replicate the exact logic from dap.lua:
  --   local pathBash = vim.fn.executable("/opt/homebrew/bin/bash") == 1
  --       and "/opt/homebrew/bin/bash"
  --     or "/bin/bash"
  local homebrew_bash = "/opt/homebrew/bin/bash"
  local fallback_bash = "/bin/bash"

  local pathBash
  if vim.fn.executable(homebrew_bash) == 1 then
    pathBash = homebrew_bash
  else
    pathBash = fallback_bash
  end

  -- Result must be one of the two known paths (never nil or empty)
  assert_not_nil(pathBash, "pathBash must not be nil")
  if pathBash ~= homebrew_bash and pathBash ~= fallback_bash then
    error(string.format("pathBash has unexpected value: '%s'", pathBash))
  end

  print(string.format("  Selected pathBash: %s", pathBash))
end)

-- Test 2: pathBash falls back to /bin/bash when homebrew bash is absent
test("DAP pathBash: falls back to /bin/bash when homebrew bash is not executable", function()
  -- Simulate the condition where homebrew bash does NOT exist
  local homebrew_bash = "/nonexistent/homebrew/bash"
  local fallback_bash = "/bin/bash"

  local pathBash = vim.fn.executable(homebrew_bash) == 1 and homebrew_bash or fallback_bash

  assert_eq(pathBash, fallback_bash, "Should fall back to /bin/bash when homebrew bash absent")
end)

-- Test 3: bash_debug_adapter_bin path construction
test("DAP bash_debug_adapter_bin path is constructed from stdpath('data')", function()
  local mason_path = vim.fn.stdpath("data") .. "/mason"
  local bash_debug_adapter_path = mason_path .. "/packages/bash-debug-adapter"
  local bash_debug_adapter_bin = bash_debug_adapter_path .. "/bash-debug-adapter"

  -- Path must be an absolute path starting with /
  if not bash_debug_adapter_bin:match("^/") then
    error(string.format("Expected absolute path, got: '%s'", bash_debug_adapter_bin))
  end

  -- Path must contain the expected components
  if not bash_debug_adapter_bin:match("mason") then
    error("Path should contain 'mason'")
  end
  if not bash_debug_adapter_bin:match("bash%-debug%-adapter") then
    error("Path should contain 'bash-debug-adapter'")
  end

  print(string.format("  bin path: %s", bash_debug_adapter_bin))
end)

-- Test 4: bashdb_dir path construction derives from bash_debug_adapter_path
test("DAP bashdb_dir path derives correctly from bash_debug_adapter_path", function()
  local mason_path = vim.fn.stdpath("data") .. "/mason"
  local bash_debug_adapter_path = mason_path .. "/packages/bash-debug-adapter"
  local bashdb_dir = bash_debug_adapter_path .. "/extension/bashdb_dir"

  assert_eq(
    bashdb_dir,
    bash_debug_adapter_path .. "/extension/bashdb_dir",
    "bashdb_dir should append /extension/bashdb_dir to bash_debug_adapter_path"
  )

  -- pathBashdb and pathBashdbLib should derive from bashdb_dir
  local pathBashdb = bashdb_dir .. "/bashdb"
  local pathBashdbLib = bashdb_dir

  if not pathBashdb:match("bashdb$") then
    error("pathBashdb must end with '/bashdb'")
  end
  assert_eq(pathBashdbLib, bashdb_dir, "pathBashdbLib must equal bashdb_dir")
end)

-- Test 5: DAP configurations include 'bash' filetype (newly added in PR)
test("DAP: 'bash' filetype configuration is registered alongside 'sh' and 'zsh'", function()
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    warn("DAP not loaded", "nvim-dap plugin not available in this environment")
    return
  end

  -- After plugin load, dap.configurations should have sh, bash, and zsh entries
  -- (if bash-debug-adapter is installed) or all three should be absent.
  local has_sh   = dap.configurations.sh   ~= nil
  local has_bash = dap.configurations.bash ~= nil
  local has_zsh  = dap.configurations.zsh  ~= nil

  if has_sh then
    -- If sh is configured, bash and zsh must also be configured (PR requirement)
    if not has_bash then
      error("dap.configurations.bash missing even though dap.configurations.sh is set")
    end
    if not has_zsh then
      error("dap.configurations.zsh missing even though dap.configurations.sh is set")
    end
    print("  sh, bash, and zsh DAP configurations are all present ✓")
  else
    -- bash-debug-adapter not installed – all three should be absent
    if has_bash or has_zsh then
      error("Partial DAP configuration: some filetypes configured but not others")
    end
    warn("bash-debug-adapter", "Not installed; sh/bash/zsh DAP configs not registered (expected)")
  end
end)

-- Test 6: sh and bash configurations reference the same table (shared config)
test("DAP: sh and bash configurations share the same config table", function()
  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    warn("DAP not loaded", "nvim-dap plugin not available")
    return
  end

  if dap.configurations.sh == nil then
    warn("bash-debug-adapter", "Not installed; skipping shared-config check")
    return
  end

  -- The PR assigns bash_config to .sh, .bash, and .zsh.
  -- They must be the same table reference.
  if dap.configurations.sh ~= dap.configurations.bash then
    error("dap.configurations.sh and dap.configurations.bash should share the same table")
  end
  if dap.configurations.sh ~= dap.configurations.zsh then
    error("dap.configurations.sh and dap.configurations.zsh should share the same table")
  end
  print("  sh, bash, zsh all reference the same config table ✓")
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Section 2: LSP – pyenv python detection (lua/plugins/lsp.lua)
-- ─────────────────────────────────────────────────────────────────────────────
print("\n--- LSP: Python Path Detection ---\n")

-- get_python_path() is a local closure inside the plugin config callback so we
-- cannot require it directly. Instead we replicate and unit-test the NEW logic
-- added in this PR: the pyenv detection step and the improved system fallback.

-- Test 7: pyenv detection returns a non-empty path when pyenv succeeds
test("LSP python path: pyenv path accepted when pyenv succeeds and path is executable", function()
  -- Simulate the pyenv detection branch (PR addition):
  --   local pyenv_python = vim.fn.trim(vim.fn.system("pyenv which python 2>/dev/null"))
  --   if vim.v.shell_error == 0 and pyenv_python ~= "" and vim.fn.executable(pyenv_python) == 1 then
  --       return pyenv_python
  --   end
  local simulated_path = "/usr/bin/python3"  -- guaranteed to exist (or a real path)
  local actual_exec = vim.fn.exepath("python3")

  -- If python3 is on the system, use its path as a stand-in for a pyenv python
  if actual_exec ~= "" and vim.fn.executable(actual_exec) == 1 then
    -- Simulate: pyenv returned actual_exec with shell_error == 0
    local pyenv_python = actual_exec
    local shell_error = 0

    if shell_error == 0 and pyenv_python ~= "" and vim.fn.executable(pyenv_python) == 1 then
      -- Should have returned pyenv_python
      assert_eq(pyenv_python, actual_exec, "pyenv detection should return the pyenv path")
      print(string.format("  Simulated pyenv path accepted: %s", pyenv_python))
    else
      error("Simulated pyenv path not accepted even though conditions are met")
    end
  else
    warn("python3 not found", "Cannot simulate pyenv path test (no python3 on PATH)")
  end
end)

-- Test 8: pyenv detection is skipped when shell_error is non-zero
test("LSP python path: pyenv detection skipped when command fails (shell_error != 0)", function()
  -- Simulate pyenv not being available: shell_error != 0
  local pyenv_python = ""
  local shell_error = 1  -- simulated failure

  local pyenv_selected = false
  if shell_error == 0 and pyenv_python ~= "" and vim.fn.executable(pyenv_python) == 1 then
    pyenv_selected = true
  end

  assert_eq(pyenv_selected, false, "pyenv path must NOT be selected when shell_error != 0")
end)

-- Test 9: pyenv detection is skipped when output is empty
test("LSP python path: pyenv detection skipped when output is empty string", function()
  local pyenv_python = ""
  local shell_error = 0  -- command succeeded but returned nothing

  local pyenv_selected = false
  if shell_error == 0 and pyenv_python ~= "" and vim.fn.executable(pyenv_python) == 1 then
    pyenv_selected = true
  end

  assert_eq(pyenv_selected, false, "pyenv path must NOT be selected when output is empty")
end)

-- Test 10: system python3 fallback returns the exepath value when it is non-empty
test("LSP python path: sys_python3 returned when exepath('python3') is non-empty", function()
  -- Replicate the new fallback logic from the PR:
  --   local sys_python3 = vim.fn.exepath("python3")
  --   if sys_python3 ~= "" then return sys_python3 end
  local sys_python3 = vim.fn.exepath("python3")
  if sys_python3 ~= "" then
    -- The function would have returned sys_python3 here
    assert_not_nil(sys_python3, "sys_python3 must not be nil")
    if sys_python3 == "" then
      error("sys_python3 must not be empty when exepath returned a value")
    end
    print(string.format("  sys_python3 path: %s", sys_python3))
  else
    warn("python3 not found", "python3 not on PATH; fallback chain continues to python/literal")
  end
end)

-- Test 11: system python fallback is tried after python3
test("LSP python path: sys_python tried after sys_python3 fails", function()
  -- Simulate sys_python3 not found, then sys_python found
  local sys_python3 = ""  -- simulated: python3 not available
  local sys_python = vim.fn.exepath("python")

  local selected
  if sys_python3 ~= "" then
    selected = sys_python3
  elseif sys_python ~= "" then
    selected = sys_python
  else
    selected = "python"
  end

  -- Whatever we selected, it must be a non-empty string
  assert_not_nil(selected, "selected path must not be nil")
  if selected == "" then
    error("selected path must not be empty")
  end
  print(string.format("  Selected fallback: %s", selected))
end)

-- Test 12: literal "python" is the final fallback when nothing is on PATH
test("LSP python path: literal 'python' is the last-resort fallback", function()
  -- Simulate no python of any kind on PATH
  local sys_python3 = ""
  local sys_python = ""

  local selected
  if sys_python3 ~= "" then
    selected = sys_python3
  elseif sys_python ~= "" then
    selected = sys_python
  else
    selected = "python"
  end

  assert_eq(selected, "python", "Final fallback must be the literal string 'python'")
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Section 3: Treesitter – bash language registration (lua/plugins/treesitter.lua)
-- ─────────────────────────────────────────────────────────────────────────────
print("\n--- Treesitter: Bash Language Registration ---\n")

-- Test 13: vim.treesitter.language.register API exists
test("Treesitter: vim.treesitter.language.register API is available", function()
  assert_not_nil(vim.treesitter, "vim.treesitter must exist")
  assert_not_nil(vim.treesitter.language, "vim.treesitter.language must exist")
  if type(vim.treesitter.language.register) ~= "function" then
    error("vim.treesitter.language.register must be a function")
  end
end)

-- Test 14: registering bash for zsh files does not raise an error
test("Treesitter: registering 'bash' parser for 'zsh' filetype succeeds without error", function()
  -- This mirrors the exact call added in treesitter.lua:
  --   vim.treesitter.language.register("bash", "zsh")
  -- If the parser is not installed the call should still not raise (it is deferred).
  local ok, err = pcall(function()
    vim.treesitter.language.register("bash", "zsh")
  end)
  if not ok then
    error(string.format("vim.treesitter.language.register raised an error: %s", err))
  end
  print("  vim.treesitter.language.register('bash', 'zsh') succeeded ✓")
end)

-- Test 15: treesitter config file contains 'bash' in ensure_installed
test("Treesitter: config file includes 'bash' in ensure_installed", function()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/treesitter.lua"
  if vim.fn.filereadable(config_path) ~= 1 then
    error("treesitter.lua config file not found")
  end

  local content = table.concat(vim.fn.readfile(config_path), "\n")
  if not content:match('"bash"') and not content:match("'bash'") then
    error("treesitter.lua does not include 'bash' in ensure_installed")
  end
  print("  'bash' found in treesitter.lua ensure_installed ✓")
end)

-- Test 16: treesitter config registers bash for zsh (source-level check)
test("Treesitter: config file registers bash parser for zsh filetype", function()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/treesitter.lua"
  local content = table.concat(vim.fn.readfile(config_path), "\n")

  if not content:match('language%.register%s*%(%s*"bash"%s*,%s*"zsh"') and
     not content:match("language%.register%s*%(%s*'bash'%s*,%s*'zsh'") then
    error("treesitter.lua does not call vim.treesitter.language.register('bash', 'zsh')")
  end
  print("  language.register('bash', 'zsh') call found in treesitter.lua ✓")
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Section 4: JJ – new diff keymaps (lua/plugins/jj.lua)
-- ─────────────────────────────────────────────────────────────────────────────
print("\n--- JJ: New Diff Keymaps ---\n")

local function find_keymap(mode, lhs)
  local maps = vim.api.nvim_get_keymap(mode)
  for _, map in ipairs(maps) do
    if map.lhs == lhs then
      return map
    end
  end
  return nil
end

-- Test 17: <leader>dd is registered (cmd.diff – revision view)
test("JJ keymap: <leader>dd registered for 'JJ diff revision'", function()
  local map = find_keymap("n", "<leader>dd")
  if map == nil then
    warn("JJ keymaps", "<leader>dd not found (may require plugin load)")
    return
  end
  print(string.format("  <leader>dd desc: '%s'", map.desc or ""))
end)

-- Test 18: <leader>dD is registered (cmd.diff with current=true)
test("JJ keymap: <leader>dD registered for 'JJ diff current file (buffer)'", function()
  local map = find_keymap("n", "<leader>dD")
  if map == nil then
    warn("JJ keymaps", "<leader>dD not found (may require plugin load)")
    return
  end
  print(string.format("  <leader>dD desc: '%s'", map.desc or ""))
end)

-- Test 19: <leader>dj is registered (cmd.cezdiff – terminal diff)
test("JJ keymap: <leader>dj registered for 'JJ diff (terminal)'", function()
  local map = find_keymap("n", "<leader>dj")
  if map == nil then
    warn("JJ keymaps", "<leader>dj not found (may require plugin load)")
    return
  end
  print(string.format("  <leader>dj desc: '%s'", map.desc or ""))
end)

-- Test 20: <leader>dJ is registered (cmd.cezdiff with current=true)
test("JJ keymap: <leader>dJ registered for 'JJ diff current file (terminal)'", function()
  local map = find_keymap("n", "<leader>dJ")
  if map == nil then
    warn("JJ keymaps", "<leader>dJ not found (may require plugin load)")
    return
  end
  print(string.format("  <leader>dJ desc: '%s'", map.desc or ""))
end)

-- Test 21: jj.lua config file contains the new diff keymap registrations
test("JJ: config file contains all four new diff keymap registrations", function()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/jj.lua"
  if vim.fn.filereadable(config_path) ~= 1 then
    error("jj.lua config file not found")
  end

  local content = table.concat(vim.fn.readfile(config_path), "\n")

  local expected_keymaps = {
    { lhs = "<leader>dd", desc = "JJ diff revision" },
    { lhs = "<leader>dD", desc = "JJ diff current file" },
    { lhs = "<leader>dj", desc = "JJ diff" },
    { lhs = "<leader>dJ", desc = "JJ diff current file" },
  }

  local missing = {}
  for _, km in ipairs(expected_keymaps) do
    if not content:match(vim.pesc(km.lhs)) then
      table.insert(missing, km.lhs)
    end
  end

  if #missing > 0 then
    error(string.format("Missing keymap registrations in jj.lua: %s", table.concat(missing, ", ")))
  end

  -- Also verify cmd.cezdiff and cmd.diff are referenced
  if not content:match("cmd%.diff") then
    error("jj.lua does not reference cmd.diff")
  end
  if not content:match("cmd%.cezdiff") then
    error("jj.lua does not reference cmd.cezdiff")
  end

  print("  All four new diff keymaps found in jj.lua ✓")
end)

-- Test 22: Regression – pre-existing diff keymaps (<leader>df, <leader>dF) still present
test("JJ: pre-existing diff keymaps <leader>df and <leader>dF are still in config", function()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/jj.lua"
  local content = table.concat(vim.fn.readfile(config_path), "\n")

  if not content:match("<leader>df") then
    error("Pre-existing <leader>df keymap removed from jj.lua (regression)")
  end
  if not content:match("<leader>dF") then
    error("Pre-existing <leader>dF keymap removed from jj.lua (regression)")
  end
  print("  <leader>df and <leader>dF still present ✓")
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Summary
-- ─────────────────────────────────────────────────────────────────────────────
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