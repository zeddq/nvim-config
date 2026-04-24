-- Test Suite: VCS Keymaps Dispatch (automates the 10 "manual" tests from test_commands.lua)
--
-- Strategy: load lua/plugins/vcs-keymaps.lua, execute its config() under a
-- fully mocked `utils.vcs` module (so we can force detect_vcs_type to
-- return "jj" or "git" at will), with vim.cmd and vim.notify captured.
-- For each keymap lhs we fetch its callback via vim.fn.maparg and invoke
-- it under each VCS mode, asserting correct dispatch.

local script_dir = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

local jj_mock = require("mocks.jj_mock")

local results = { passed = 0, failed = 0, tests = {} }

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

local function assert_true(cond, msg)
  if not cond then error(msg or "Expected truthy") end
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error(string.format("%s: expected %s, got %s", msg or "eq", tostring(b), tostring(a)))
  end
end

print("\n=== VCS Keymaps Dispatch Tests ===\n")

-- ============================================================================
-- Mocks
-- ============================================================================

-- Mock utils.vcs with a settable detect type and clear_cache counter
local vcs_state = {
  current_type = "jj",
  clear_cache_count = 0,
}
local vcs_stub = {
  debug = false,
  detect_vcs_type = function() return vcs_state.current_type end,
  get_cached_vcs_type = function() return vcs_state.current_type end,
  is_jj_repo = function() return vcs_state.current_type == "jj" end,
  is_git_repo = function() return vcs_state.current_type == "git" end,
  get_repo_root = function() return "/fake/repo" end,
  get_cache_stats = function()
    return { total_entries = 1, valid_entries = 1, expired_entries = 0, cache_ttl_ms = 5000 }
  end,
  clear_cache = function()
    vcs_state.clear_cache_count = vcs_state.clear_cache_count + 1
  end,
}
package.loaded["utils.vcs"] = vcs_stub

-- Install jj_mock (not strictly needed since vcs-keymaps uses vim.cmd("J ..."),
-- but we install it so any code path requiring jj.nvim stays stubbed).
jj_mock.install()

-- Capture vim.cmd and vim.notify
local cmd_calls = {}
local notify_calls = {}
local orig_cmd = vim.cmd
local orig_notify = vim.notify

-- vim.cmd can be called as function OR table-indexed (vim.cmd.split). Wrap as function proxy.
local cmd_proxy = setmetatable({}, {
  __call = function(_, arg)
    table.insert(cmd_calls, tostring(arg))
  end,
  __index = function(_, name)
    return function(...)
      table.insert(cmd_calls, name)
    end
  end,
})
vim.cmd = cmd_proxy

vim.notify = function(msg, level, opts)
  table.insert(notify_calls, { msg = msg, level = level, opts = opts })
end

local function reset_capture()
  cmd_calls = {}
  notify_calls = {}
  jj_mock.reset()
  vcs_state.clear_cache_count = 0
end

-- ============================================================================
-- Load vcs-keymaps and execute its config
-- ============================================================================

package.loaded["plugins.vcs-keymaps"] = nil
local spec = require("plugins.vcs-keymaps")
local entry = spec[1]
assert(type(entry.config) == "function", "vcs-keymaps config must be a function")

local config_ok, config_err = pcall(entry.config)
test("vcs-keymaps config() executes without error", function()
  if not config_ok then error("config() raised: " .. tostring(config_err)) end
end)

-- ============================================================================
-- Helpers
-- ============================================================================

-- Invoke the normal-mode keymap callback for lhs
local function invoke_keymap(lhs)
  local m = vim.fn.maparg(lhs, "n", false, true)
  assert_true(m ~= nil and m.callback ~= nil, "No callback mapping for " .. lhs)
  m.callback()
end

local function cmd_log_contains(needle)
  for _, c in ipairs(cmd_calls) do
    if c:find(needle, 1, true) then return true end
  end
  return false
end

local function notify_log_contains(needle)
  for _, n in ipairs(notify_calls) do
    if type(n.msg) == "string" and n.msg:find(needle, 1, true) then return true end
  end
  return false
end

-- ============================================================================
-- Tests — jj branch
-- ============================================================================

vcs_state.current_type = "jj"

test("<leader>gs in jj repo dispatches `J status`", function()
  reset_capture()
  invoke_keymap("<leader>gs")
  assert_true(cmd_log_contains("J status"), "Expected vim.cmd('J status'), got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>gl in jj repo dispatches `J log`", function()
  reset_capture()
  invoke_keymap("<leader>gl")
  assert_true(cmd_log_contains("J log"), "Expected vim.cmd('J log'), got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>gd in jj repo dispatches `J diff`", function()
  reset_capture()
  invoke_keymap("<leader>gd")
  assert_true(cmd_log_contains("J diff"), "Expected vim.cmd('J diff'), got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>gc in jj repo dispatches `J describe`", function()
  reset_capture()
  invoke_keymap("<leader>gc")
  assert_true(cmd_log_contains("J describe"), "Expected vim.cmd('J describe'), got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>gn in jj repo dispatches `J new`", function()
  reset_capture()
  invoke_keymap("<leader>gn")
  assert_true(cmd_log_contains("J new"), "Expected vim.cmd('J new'), got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>gS in jj repo dispatches `J squash`", function()
  reset_capture()
  invoke_keymap("<leader>gS")
  assert_true(cmd_log_contains("J squash"), "Expected vim.cmd('J squash'), got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>ge in jj repo dispatches `J edit`", function()
  reset_capture()
  invoke_keymap("<leader>ge")
  assert_true(cmd_log_contains("J edit"), "Expected vim.cmd('J edit'), got: "
    .. table.concat(cmd_calls, " | "))
end)

-- ============================================================================
-- Tests — git branch (jj-only keymaps should notify, shared keymaps run git)
-- ============================================================================

vcs_state.current_type = "git"

test("<leader>gs in git repo opens a terminal with `git status`", function()
  reset_capture()
  invoke_keymap("<leader>gs")
  -- Terminal split uses: "belowright 15split | terminal git status"
  -- and "startinsert"
  assert_true(cmd_log_contains("git status"), "Expected vim.cmd to contain 'git status', got: "
    .. table.concat(cmd_calls, " | "))
  assert_true(not cmd_log_contains("J status"), "Should NOT dispatch 'J status' in git repo")
end)

test("<leader>gl in git repo runs git log in terminal", function()
  reset_capture()
  invoke_keymap("<leader>gl")
  assert_true(cmd_log_contains("git log"), "Expected terminal git log, got: "
    .. table.concat(cmd_calls, " | "))
  assert_true(not cmd_log_contains("J log"), "Should NOT dispatch 'J log' in git repo")
end)

test("<leader>gd in git repo runs git diff in terminal", function()
  reset_capture()
  invoke_keymap("<leader>gd")
  assert_true(cmd_log_contains("git diff"), "Expected terminal git diff, got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>gc in git repo runs git commit in terminal", function()
  reset_capture()
  invoke_keymap("<leader>gc")
  assert_true(cmd_log_contains("git commit"), "Expected terminal git commit, got: "
    .. table.concat(cmd_calls, " | "))
end)

test("<leader>gn in git repo notifies 'jj new is only available'", function()
  reset_capture()
  invoke_keymap("<leader>gn")
  assert_true(notify_log_contains("jj new is only available"),
    "Expected notify about jj-only keymap")
  assert_true(not cmd_log_contains("J new"), "Should NOT dispatch 'J new' in git repo")
end)

test("<leader>gS in git repo notifies 'jj squash is only available'", function()
  reset_capture()
  invoke_keymap("<leader>gS")
  assert_true(notify_log_contains("jj squash is only available"),
    "Expected notify about jj-only squash")
end)

test("<leader>ge in git repo notifies 'jj edit is only available'", function()
  reset_capture()
  invoke_keymap("<leader>ge")
  assert_true(notify_log_contains("jj edit is only available"),
    "Expected notify about jj-only edit")
end)

-- ============================================================================
-- Tests — utility keymaps (VCS-independent)
-- ============================================================================

test("<leader>gR calls utils.vcs.clear_cache and notifies", function()
  reset_capture()
  invoke_keymap("<leader>gR")
  assert_eq(vcs_state.clear_cache_count, 1, "clear_cache should have been called once")
  assert_true(notify_log_contains("VCS cache cleared"), "Expected notify about cache clear")
end)

test("<leader>g? notifies with VCS info (type/root/cache)", function()
  reset_capture()
  invoke_keymap("<leader>g?")
  assert_true(#notify_calls >= 1, "Expected at least one notify call")
  local msg = notify_calls[1].msg
  assert_true(type(msg) == "string" and msg:find("VCS Information"),
    "Expected VCS Information header in notify message, got: " .. tostring(msg))
  assert_true(msg:find("Type: "), "Expected 'Type: ' in VCS info notify")
  assert_true(msg:find("Root: "), "Expected 'Root: ' in VCS info notify")
  assert_true(msg:find("Cache: "), "Expected 'Cache: ' in VCS info notify")
end)

-- ============================================================================
-- "none" VCS branch: shared keymaps should notify "Not in a VCS repository"
-- ============================================================================

vcs_state.current_type = "none"

test("<leader>gs in non-VCS dir notifies 'Not in a VCS repository'", function()
  reset_capture()
  invoke_keymap("<leader>gs")
  assert_true(notify_log_contains("Not in a VCS repository"),
    "Expected 'Not in a VCS repository' warning")
end)

-- ============================================================================
-- Cleanup
-- ============================================================================

vim.cmd = orig_cmd
vim.notify = orig_notify
jj_mock.uninstall()
package.loaded["utils.vcs"] = nil

print("\n=== Test Summary ===")
print(string.format("Passed: %d", results.passed))
print(string.format("Failed: %d", results.failed))
print(string.format("Total: %d", results.passed + results.failed))

if results.failed > 0 then
  print("\nFailed tests:")
  for _, t in ipairs(results.tests) do
    if t.status == "FAIL" then
      print(string.format("  - %s: %s", t.name, t.error))
    end
  end
  vim.cmd("cquit 1")
else
  print("\nAll tests passed!")
  vim.cmd("qall!")
end
