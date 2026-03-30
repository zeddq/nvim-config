-- Mock module for jj.nvim
-- Provides the API surface that our wrapper code (vcs-keymaps, commands) calls,
-- without requiring the real jj.nvim plugin to be loaded by lazy.nvim.
--
-- Usage: require("mocks.jj_mock").install()
--   This injects mocks into package.preload so subsequent require("jj")
--   and require("jj.cmd") return the mock instead of hitting the filesystem.

local M = {}

-- Call log — tests can inspect this to verify dispatch behavior
M.calls = {}

local function record_call(fn_name, args)
  table.insert(M.calls, { fn = fn_name, args = args or {} })
end

--- Reset the call log between tests
function M.reset()
  M.calls = {}
end

--- Install mocks into package.preload
function M.install()
  M.reset()

  -- Mock jj.cmd module
  local mock_cmd = {
    config = {
      describe_editor = "buffer",
    },
    status = function(opts)
      record_call("status", opts)
      return true
    end,
    log = function(opts)
      record_call("log", opts)
      return true
    end,
    describe = function(opts)
      record_call("describe", opts)
      return true
    end,
    new = function(opts)
      record_call("new", opts)
      return true
    end,
    edit = function(opts)
      record_call("edit", opts)
      return true
    end,
    diff = function(opts)
      record_call("diff", opts)
      return true
    end,
    squash = function(opts)
      record_call("squash", opts)
      return true
    end,
  }

  -- Mock jj root module
  local mock_jj = {
    setup = function(opts)
      record_call("setup", opts)
    end,
    cmd = mock_cmd,
  }

  -- Inject into package.preload (checked before filesystem)
  package.preload["jj"] = function()
    return mock_jj
  end
  package.preload["jj.cmd"] = function()
    return mock_cmd
  end

  return mock_jj, mock_cmd
end

--- Remove mocks from package.preload and loaded cache
function M.uninstall()
  package.preload["jj"] = nil
  package.preload["jj.cmd"] = nil
  package.loaded["jj"] = nil
  package.loaded["jj.cmd"] = nil
end

return M
