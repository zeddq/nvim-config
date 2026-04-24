-- Test Suite: utils.jj_merge
-- Synthesizes window layouts to verify merge output detection, role mapping, and keymap guards

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

local function assert_nil(value, msg)
  if value ~= nil then
    error(string.format("%s\nExpected nil, got: %s", msg or "Assertion failed", tostring(value)))
  end
end

local function assert_true(value, msg)
  if not value then
    error(msg or "Expected truthy value")
  end
end

print("\n=== utils.jj_merge Tests ===\n")

-- Reset any prior tab state before each test
local function reset_tab()
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  -- Wipe any extra buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == "" and not vim.bo[buf].modified then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
  vim.g.jj_merge_outbuf = nil
end

-- Access private functions by re-evaluating the module file with a small shim.
-- The module doesn't expose find_output_win/get_role_win on M, so we expose them
-- via a loader wrapper that captures the locals through the environment.
local function load_jj_merge_with_privates()
  local src_path = debug.getinfo(1, "S").source:sub(2):gsub("tests/test_jj_merge%.lua$", "lua/utils/jj_merge.lua")
  local chunk, err = loadfile(src_path)
  if not chunk then
    error("Failed to load jj_merge: " .. tostring(err))
  end
  -- Don't need privates via a wrapper: we'll test M.take and M.setup_keymaps,
  -- which indirectly exercise find_output_win/get_role_win. Direct unit tests
  -- of the private helpers use the same public entry points with crafted layouts.
  return chunk()
end

-- Helper: create a new scratch buffer (not listed, nofile)
local function new_scratch_buf(modifiable)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].modifiable = modifiable ~= false
  return buf
end

-- Helper: set a window into diff mode
local function set_diff(win, enabled)
  vim.api.nvim_set_option_value("diff", enabled, { win = win })
end

-- Helper: capture notify messages
local function with_notify_capture(fn)
  local captured = {}
  local original = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(captured, { msg = msg, level = level, opts = opts })
  end
  local ok, err = pcall(fn)
  vim.notify = original
  if not ok then
    error(err)
  end
  return captured
end

-- Ensure test buffers have a reasonable filetype so diff doesn't complain
local function fill_buf(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { "a", "b", "c" })
end

-- ===== Tests =====

test("find_output_win returns unique non-diff modifiable candidate (3-way layout)", function()
  reset_tab()
  local out_buf = new_scratch_buf(true)
  local l_buf = new_scratch_buf(true)
  local b_buf = new_scratch_buf(true)
  local r_buf = new_scratch_buf(true)
  fill_buf(out_buf); fill_buf(l_buf); fill_buf(b_buf); fill_buf(r_buf)

  -- Layout: top row has three diff windows (left, base, right); bottom is output
  vim.api.nvim_set_current_buf(l_buf)
  vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(b_buf)
  vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(r_buf)
  vim.cmd("split")
  vim.api.nvim_set_current_buf(out_buf)

  -- Mark top three as diff
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    if buf ~= out_buf then
      set_diff(w, true)
    else
      set_diff(w, false)
    end
  end

  -- Indirect test: setup_keymaps() should succeed and register the guard var
  package.loaded["utils.jj_merge"] = nil
  local jj_merge = require("utils.jj_merge")
  jj_merge.setup_keymaps()

  local ok, already = pcall(vim.api.nvim_buf_get_var, out_buf, "jj_merge_keymaps_set")
  assert_true(ok and already == true, "output buffer should have jj_merge_keymaps_set = true")
end)

test("find_output_win returns nil/nil when two non-diff candidates exist", function()
  reset_tab()
  -- Two modifiable non-diff windows, both qualify as output → ambiguous
  local a = new_scratch_buf(true); fill_buf(a)
  local b = new_scratch_buf(true); fill_buf(b)
  local c = new_scratch_buf(true); fill_buf(c) -- one diff window so get_diff_wins returns something
  local d = new_scratch_buf(true); fill_buf(d)

  vim.api.nvim_set_current_buf(a)
  vim.cmd("split"); vim.api.nvim_set_current_buf(b)
  vim.cmd("split"); vim.api.nvim_set_current_buf(c)
  vim.cmd("split"); vim.api.nvim_set_current_buf(d)

  -- Mark two as diff, two as non-diff
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    if buf == c or buf == d then
      set_diff(w, true)
    else
      set_diff(w, false)
    end
  end

  -- With two ambiguous output candidates, setup_keymaps should NOT register keymaps
  -- (find_output_win returns nil, so the guard var is never set).
  package.loaded["utils.jj_merge"] = nil
  local jj_merge = require("utils.jj_merge")
  jj_merge.setup_keymaps()

  local ok_a, val_a = pcall(vim.api.nvim_buf_get_var, a, "jj_merge_keymaps_set")
  local ok_b, val_b = pcall(vim.api.nvim_buf_get_var, b, "jj_merge_keymaps_set")
  assert_true(not (ok_a and val_a), "buffer a should not have guard var set")
  assert_true(not (ok_b and val_b), "buffer b should not have guard var set")
end)

test("vim.g.jj_merge_outbuf is honored even with other non-diff candidates", function()
  reset_tab()
  local forced = new_scratch_buf(true); fill_buf(forced)
  local other = new_scratch_buf(true); fill_buf(other) -- would otherwise be ambiguous
  local d1 = new_scratch_buf(true); fill_buf(d1)
  local d2 = new_scratch_buf(true); fill_buf(d2)

  vim.api.nvim_set_current_buf(d1); vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(d2); vim.cmd("split")
  vim.api.nvim_set_current_buf(other); vim.cmd("split")
  vim.api.nvim_set_current_buf(forced)

  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    set_diff(w, buf == d1 or buf == d2)
  end

  vim.g.jj_merge_outbuf = forced

  package.loaded["utils.jj_merge"] = nil
  local jj_merge = require("utils.jj_merge")
  jj_merge.setup_keymaps()

  local ok, already = pcall(vim.api.nvim_buf_get_var, forced, "jj_merge_keymaps_set")
  assert_true(ok and already == true, "forced output buffer should have guard var set")

  vim.g.jj_merge_outbuf = nil
end)

test("floating windows are ignored by output detection", function()
  reset_tab()
  local out_buf = new_scratch_buf(true); fill_buf(out_buf)
  local l_buf = new_scratch_buf(true); fill_buf(l_buf)
  local r_buf = new_scratch_buf(true); fill_buf(r_buf)
  local float_buf = new_scratch_buf(true); fill_buf(float_buf)

  vim.api.nvim_set_current_buf(l_buf); vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(r_buf); vim.cmd("split")
  vim.api.nvim_set_current_buf(out_buf)

  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    set_diff(w, buf == l_buf or buf == r_buf)
  end

  -- Open a floating, non-diff, modifiable window → must NOT be treated as output
  vim.api.nvim_open_win(float_buf, false, {
    relative = "editor", width = 10, height = 3, row = 1, col = 1,
  })

  package.loaded["utils.jj_merge"] = nil
  local jj_merge = require("utils.jj_merge")
  jj_merge.setup_keymaps()

  local ok, already = pcall(vim.api.nvim_buf_get_var, out_buf, "jj_merge_keymaps_set")
  assert_true(ok and already == true, "output buffer (non-float) should be selected despite a floating window")
  local float_ok, float_val = pcall(vim.api.nvim_buf_get_var, float_buf, "jj_merge_keymaps_set")
  assert_true(not (float_ok and float_val), "floating buffer should not have guard var set")
end)

test("M.take('base') in 2-way layout emits WARN notify", function()
  reset_tab()
  local left = new_scratch_buf(true); fill_buf(left)
  local right = new_scratch_buf(true); fill_buf(right)

  vim.api.nvim_set_current_buf(left)
  vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(right)

  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    set_diff(w, true)  -- both diff → no non-diff output candidate
  end

  package.loaded["utils.jj_merge"] = nil
  local jj_merge = require("utils.jj_merge")

  local captured = with_notify_capture(function()
    jj_merge.take("base")
  end)

  assert_true(#captured > 0, "take('base') should emit at least one notify")
  local found_warn = false
  for _, c in ipairs(captured) do
    if c.level == vim.log.levels.WARN and type(c.msg) == "string" and c.msg:find("base") then
      found_warn = true
      break
    end
  end
  assert_true(found_warn, "should emit a WARN mentioning 'base'")
end)

test("setup_keymaps registers buffer-local <leader>ml/mb/mr once (3-way)", function()
  reset_tab()
  local out_buf = new_scratch_buf(true); fill_buf(out_buf)
  local l_buf = new_scratch_buf(true); fill_buf(l_buf)
  local b_buf = new_scratch_buf(true); fill_buf(b_buf)
  local r_buf = new_scratch_buf(true); fill_buf(r_buf)

  vim.api.nvim_set_current_buf(l_buf); vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(b_buf); vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(r_buf); vim.cmd("split")
  vim.api.nvim_set_current_buf(out_buf)

  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    set_diff(w, buf ~= out_buf)
  end

  package.loaded["utils.jj_merge"] = nil
  local jj_merge = require("utils.jj_merge")

  jj_merge.setup_keymaps()
  jj_merge.setup_keymaps()  -- second call must be a no-op

  local function count_lhs(lhs)
    local n = 0
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(out_buf, "n")) do
      if m.lhs == lhs then n = n + 1 end
    end
    return n
  end

  -- <leader> expands to " "; buf-local keymaps surface as " ml", etc.
  local ml = count_lhs(" ml")
  local mb = count_lhs(" mb")
  local mr = count_lhs(" mr")
  assert_eq(ml, 1, "<leader>ml should be mapped exactly once")
  assert_eq(mb, 1, "<leader>mb should be mapped exactly once (3-way)")
  assert_eq(mr, 1, "<leader>mr should be mapped exactly once")

  local ok, already = pcall(vim.api.nvim_buf_get_var, out_buf, "jj_merge_keymaps_set")
  assert_true(ok and already == true, "guard var should be set")
end)

test("setup_keymaps in 2-way layout registers ml/mr but not mb", function()
  reset_tab()
  local out_buf = new_scratch_buf(true); fill_buf(out_buf)
  local l_buf = new_scratch_buf(true); fill_buf(l_buf)
  local r_buf = new_scratch_buf(true); fill_buf(r_buf)

  vim.api.nvim_set_current_buf(l_buf); vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(r_buf); vim.cmd("split")
  vim.api.nvim_set_current_buf(out_buf)

  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    set_diff(w, buf ~= out_buf)
  end

  package.loaded["utils.jj_merge"] = nil
  local jj_merge = require("utils.jj_merge")
  jj_merge.setup_keymaps()

  local function count_lhs(lhs)
    local n = 0
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(out_buf, "n")) do
      if m.lhs == lhs then n = n + 1 end
    end
    return n
  end

  assert_eq(count_lhs(" ml"), 1, "<leader>ml should be mapped (2-way)")
  assert_eq(count_lhs(" mr"), 1, "<leader>mr should be mapped (2-way)")
  assert_eq(count_lhs(" mb"), 0, "<leader>mb should NOT be mapped in 2-way")
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
