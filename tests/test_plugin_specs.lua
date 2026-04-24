-- Test Suite: Plugin Spec Regression Checks
-- Inspects plugin spec tables at runtime. No regex-on-source assertions.

local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.uv = vim.uv or vim.loop
package.path = table.concat({
  repo_root .. "/lua/?.lua",
  repo_root .. "/lua/?/init.lua",
  repo_root .. "/tests/?.lua",
  repo_root .. "/tests/?/init.lua",
  package.path,
}, ";")

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

local function assert_true(v, msg)
  if not v then error(msg or "Assertion failed", 2) end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s\nExpected: %s\nActual: %s",
      msg or "Assertion failed", tostring(expected), tostring(actual)), 2)
  end
end

local function list_contains(tbl, needle)
  for _, v in ipairs(tbl or {}) do
    if v == needle then return true end
  end
  return false
end

print("\n=== Plugin Spec Regression Tests ===\n")

-- ── DAP ──────────────────────────────────────────────────────────────────────
test("DAP spec declares core plugin and required dependencies", function()
  local dap_spec = require("plugins.dap")[1]
  assert_eq(dap_spec[1], "mfussenegger/nvim-dap", "First entry should be nvim-dap")
  local deps = dap_spec.dependencies or {}
  assert_true(list_contains(deps, "rcarriga/nvim-dap-ui"), "dap-ui dependency should be present")
  assert_true(list_contains(deps, "mfussenegger/nvim-dap-python"), "dap-python dependency should be present")
  assert_true(list_contains(deps, "theHamsta/nvim-dap-virtual-text"),
    "dap-virtual-text dependency should be present")
end)

test("DAP config registers bash adapter when bash-debug-adapter is executable", function()
  -- Install rich mocks for the dap ecosystem.
  local orig_executable = vim.fn.executable
  local orig_sign_define = vim.fn.sign_define
  local orig_notify = vim.notify
  local orig_popen = io.popen
  local orig_input = vim.fn.input
  local orig_create_cmd = vim.api.nvim_create_user_command

  -- Capture state
  local dap_mock = {
    adapters = {},
    configurations = { python = {} },
    listeners = {
      after = { event_initialized = {} },
      before = { event_terminated = {}, event_exited = {} },
    },
  }
  local dapui_setup_called = false
  local vtext_setup_called = false
  local dap_python_setup_arg = nil

  package.loaded["dap"] = nil
  package.loaded["dapui"] = nil
  package.loaded["nvim-dap-virtual-text"] = nil
  package.loaded["osv"] = nil
  package.loaded["dap-python"] = nil

  package.preload["dap"] = function() return dap_mock end
  package.preload["dapui"] = function()
    return { setup = function() dapui_setup_called = true end,
             open = function() end, close = function() end, toggle = function() end }
  end
  package.preload["nvim-dap-virtual-text"] = function()
    return { setup = function() vtext_setup_called = true end }
  end
  package.preload["osv"] = function()
    return { launch = function() end, run_this = function() end }
  end
  package.preload["dap-python"] = function()
    return { setup = function(p) dap_python_setup_arg = p end }
  end

  -- Force bash-debug-adapter and homebrew bash to "exist"
  vim.fn.executable = function(path)
    if type(path) == "string" and (path:match("bash%-debug%-adapter") or path == "/opt/homebrew/bin/bash") then
      return 1
    end
    return 0
  end
  vim.fn.sign_define = function() return 0 end
  vim.notify = function() end
  io.popen = function() return nil end
  vim.fn.input = function() return "" end
  vim.api.nvim_create_user_command = function() end

  local restore = function()
    vim.fn.executable = orig_executable
    vim.fn.sign_define = orig_sign_define
    vim.notify = orig_notify
    io.popen = orig_popen
    vim.fn.input = orig_input
    vim.api.nvim_create_user_command = orig_create_cmd
    package.preload["dap"] = nil
    package.preload["dapui"] = nil
    package.preload["nvim-dap-virtual-text"] = nil
    package.preload["osv"] = nil
    package.preload["dap-python"] = nil
    package.loaded["dap"] = nil
    package.loaded["dapui"] = nil
    package.loaded["nvim-dap-virtual-text"] = nil
    package.loaded["osv"] = nil
    package.loaded["dap-python"] = nil
  end

  local dap_spec = require("plugins.dap")[1]
  local ok, err = pcall(dap_spec.config)
  restore()
  if not ok then error(err) end

  assert_true(dapui_setup_called, "dapui.setup should be invoked")
  assert_true(vtext_setup_called, "nvim-dap-virtual-text setup should be invoked")
  assert_eq(dap_python_setup_arg, "python3", "dap-python should be configured with fallback python3")
  assert_true(dap_mock.adapters.nlua ~= nil, "nlua adapter should be registered")
  assert_true(dap_mock.adapters.bashdb ~= nil, "bashdb adapter should be registered when executable")
  assert_eq(dap_mock.adapters.bashdb.type, "executable", "bashdb adapter should be executable type")
  assert_true(dap_mock.configurations.sh ~= nil, "sh configuration should be set")
  assert_true(dap_mock.configurations.bash ~= nil, "bash configuration should be set")
  assert_true(dap_mock.configurations.zsh ~= nil, "zsh configuration should be set")

  local cfg = dap_mock.configurations.sh[1]
  assert_eq(cfg.type, "bashdb", "sh config should use bashdb adapter")
  assert_eq(type(cfg.cwd), "function", "cwd should be a function (resolved at launch time)")
  assert_eq(cfg.pathBash, "/opt/homebrew/bin/bash",
    "homebrew bash path should be preferred when available")
end)

test("DAP config skips bash adapter when bash-debug-adapter missing", function()
  local orig_executable = vim.fn.executable
  local orig_sign_define = vim.fn.sign_define
  local orig_notify = vim.notify
  local orig_popen = io.popen
  local orig_create_cmd = vim.api.nvim_create_user_command

  local dap_mock = {
    adapters = {},
    configurations = { python = {} },
    listeners = {
      after = { event_initialized = {} },
      before = { event_terminated = {}, event_exited = {} },
    },
  }
  package.preload["dap"] = function() return dap_mock end
  package.preload["dapui"] = function()
    return { setup = function() end, open = function() end, close = function() end, toggle = function() end }
  end
  package.preload["nvim-dap-virtual-text"] = function() return { setup = function() end } end
  package.preload["osv"] = function() return { launch = function() end, run_this = function() end } end
  package.preload["dap-python"] = function() return { setup = function() end } end
  package.loaded["dap"] = nil
  package.loaded["dapui"] = nil
  package.loaded["nvim-dap-virtual-text"] = nil
  package.loaded["osv"] = nil
  package.loaded["dap-python"] = nil

  vim.fn.executable = function() return 0 end
  vim.fn.sign_define = function() return 0 end
  local notify_called = false
  vim.notify = function() notify_called = true end
  io.popen = function() return nil end
  vim.api.nvim_create_user_command = function() end

  local restore = function()
    vim.fn.executable = orig_executable
    vim.fn.sign_define = orig_sign_define
    vim.notify = orig_notify
    io.popen = orig_popen
    vim.api.nvim_create_user_command = orig_create_cmd
    package.preload["dap"] = nil
    package.preload["dapui"] = nil
    package.preload["nvim-dap-virtual-text"] = nil
    package.preload["osv"] = nil
    package.preload["dap-python"] = nil
    package.loaded["dap"] = nil
    package.loaded["dapui"] = nil
    package.loaded["nvim-dap-virtual-text"] = nil
    package.loaded["osv"] = nil
    package.loaded["dap-python"] = nil
  end

  local dap_spec = require("plugins.dap")[1]
  local ok, err = pcall(dap_spec.config)
  restore()
  if not ok then error(err) end

  assert_true(dap_mock.adapters.bashdb == nil, "bashdb adapter should NOT be registered")
  assert_true(dap_mock.configurations.sh == nil, "sh configuration should NOT be set")
  assert_true(notify_called, "user should be notified that adapter is missing")
end)

-- ── Treesitter ────────────────────────────────────────────────────────────────
test("Treesitter config keeps expected language set", function()
  local treesitter_spec = require("plugins.treesitter")[1]
  local captured

  local orig_ts_configs = package.loaded["nvim-treesitter.configs"]
  package.loaded["nvim-treesitter.configs"] = {
    setup = function(opts) captured = opts end,
  }

  local ok, err = pcall(treesitter_spec.config)

  package.loaded["nvim-treesitter.configs"] = orig_ts_configs

  if not ok then error(err) end

  assert_true(type(captured) == "table", "Treesitter config should call setup")
  local ensure = captured.ensure_installed or {}
  for _, lang in ipairs({ "python", "lua", "vim", "vimdoc", "query" }) do
    assert_true(vim.tbl_contains(ensure, lang), "ensure_installed should include " .. lang)
  end
  assert_eq(captured.auto_install, true, "auto_install should be enabled")
end)

-- ── JJ plugin keymaps ─────────────────────────────────────────────────────────
test("JJ plugin spec targets nicolasgb/jj.nvim with snacks dependency", function()
  local jj_spec = require("plugins.jj")
  assert_eq(jj_spec[1], "nicolasgb/jj.nvim", "jj plugin spec should target nicolasgb/jj.nvim")
  assert_true(list_contains(jj_spec.dependencies or {}, "folke/snacks.nvim"),
    "jj plugin should depend on snacks.nvim")
end)

test("JJ plugin config registers documented diff keymaps", function()
  -- Install the jj mock with cezdiff added so all branches execute.
  local jj_mock = require("mocks.jj_mock")
  jj_mock.install()
  local cmd_mock = package.preload["jj.cmd"]()
  cmd_mock.cezdiff = function() end
  cmd_mock.rebase = function() end
  cmd_mock.undo = function() end
  cmd_mock.redo = function() end
  cmd_mock.bookmark_create = function() end
  cmd_mock.bookmark_delete = function() end
  cmd_mock.bookmark_move = function() end
  cmd_mock.abandon = function() end
  cmd_mock.fetch = function() end
  cmd_mock.push = function() end
  cmd_mock.open_pr = function() end
  cmd_mock.j = function() end

  package.loaded["jj.diff"] = nil
  package.preload["jj.diff"] = function()
    return { open_vdiff = function() end, open_hsplit = function() end }
  end

  package.loaded["jj.picker"] = nil
  package.preload["jj.picker"] = function()
    return { status = function() end, file_history = function() end }
  end

  -- Snapshot pre-existing mappings so we only assert on what we added.
  local pre = {}
  for _, lhs in ipairs({ "<leader>df", "<leader>dF", "<leader>dd", "<leader>dD",
                        "<leader>dj", "<leader>dJ" }) do
    pre[lhs] = vim.fn.maparg(lhs, "n", false, true)
  end

  local jj_spec = require("plugins.jj")
  local ok, err = pcall(jj_spec.config)

  local function is_mapped(lhs)
    local m = vim.fn.maparg(lhs, "n", false, true)
    return m and next(m) ~= nil
  end

  local function cleanup()
    for _, lhs in ipairs({ "<leader>df", "<leader>dF", "<leader>dd", "<leader>dD",
                          "<leader>dj", "<leader>dJ" }) do
      pcall(vim.keymap.del, "n", lhs)
    end
    jj_mock.uninstall()
    package.preload["jj.diff"] = nil
    package.preload["jj.picker"] = nil
    package.loaded["jj.diff"] = nil
    package.loaded["jj.picker"] = nil
  end

  if not ok then cleanup(); error(err) end

  for _, lhs in ipairs({ "<leader>df", "<leader>dF", "<leader>dd", "<leader>dD",
                        "<leader>dj", "<leader>dJ" }) do
    assert_true(is_mapped(lhs), "expected diff keymap " .. lhs .. " to be registered")
  end

  cleanup()
end)

print("\n=== Test Summary ===")
print(string.format("Passed: %d", results.passed))
print(string.format("Failed: %d", results.failed))
print(string.format("Total: %d", results.passed + results.failed))

if results.failed > 0 then
  print("\nFailed tests:")
  for _, t in ipairs(results.tests) do
    if t.status == "FAIL" then print(string.format("  - %s: %s", t.name, t.error)) end
  end
  vim.cmd("cquit 1")
else
  print("\nAll critical tests passed!")
  vim.cmd("qall!")
end
