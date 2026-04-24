-- Test Suite: Completion (nvim-cmp) Plugin Spec
-- Stubs `cmp`, `luasnip`, `cmp_luasnip`, and the luasnip vscode/lua
-- loaders. Captures cmp.setup(opts), asserts sources include LSP,
-- lazydev, luasnip, buffer, path, and that <C-;> is present in the
-- mapping table (per ~/.claude memory: this keybind is intentional).

local script_dir = debug.getinfo(1, "S").source:match("@(.*/)")
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

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

print("\n=== Completion Plugin Spec Tests ===\n")

-- ============================================================================
-- Mocks
-- ============================================================================

-- cmp uses cmp.config.sources(...) to merge source lists — it flattens
-- multiple arg-lists into one table. We replicate that behavior in the stub
-- so the final opts.sources reflects every name we pass in.
local cmp_setup_calls = {}
local cmp_cmdline_setup_calls = {}

local cmp_mock = {
  setup = setmetatable({}, {
    __call = function(_, opts)
      table.insert(cmp_setup_calls, opts)
    end,
    __index = function(_, key)
      if key == "cmdline" then
        return function(ch, opts)
          table.insert(cmp_cmdline_setup_calls, { channel = ch, opts = opts })
        end
      end
      return function() end
    end,
  }),
  config = {
    sources = function(...)
      local args = { ... }
      local merged = {}
      for _, list in ipairs(args) do
        for _, src in ipairs(list) do
          table.insert(merged, src)
        end
      end
      return merged
    end,
    window = {
      bordered = function() return { _bordered = true } end,
    },
  },
  mapping = setmetatable({}, {
    __call = function(_, fn, modes)
      -- A mapping(fn, modes) returns a mapping callable
      return { _map_fn = fn, _modes = modes }
    end,
    __index = function(_, key)
      -- e.g. cmp.mapping.preset.insert, cmp.mapping.complete, scroll_docs, abort, confirm
      if key == "preset" then
        return {
          insert = function(overrides) return overrides end,
          cmdline = function(overrides) return overrides or {} end,
        }
      end
      -- generic: return a function factory
      return function(arg)
        return { _key = key, _arg = arg }
      end
    end,
  }),
  visible = function() return false end,
  select_next_item = function() end,
  select_prev_item = function() end,
}

local luasnip_mock = {
  lsp_expand = function() end,
  expand_or_jumpable = function() return false end,
  expand_or_jump = function() end,
  jumpable = function() return false end,
  jump = function() end,
  loaders = {},
}

-- luasnip.loaders.from_vscode / from_lua both expose `lazy_load`
package.loaded["cmp"] = nil
package.loaded["luasnip"] = nil
package.loaded["luasnip.loaders.from_vscode"] = nil
package.loaded["luasnip.loaders.from_lua"] = nil
package.loaded["cmp_luasnip"] = nil

package.preload["cmp"] = function() return cmp_mock end
package.preload["luasnip"] = function() return luasnip_mock end
package.preload["luasnip.loaders.from_vscode"] = function()
  return { lazy_load = function() end }
end
package.preload["luasnip.loaders.from_lua"] = function()
  return { lazy_load = function() end }
end
package.preload["cmp_luasnip"] = function() return {} end

-- ============================================================================
-- Load and execute the spec
-- ============================================================================

package.loaded["plugins.completion"] = nil
local spec = require("plugins.completion")
local entry = spec[1]
assert(type(entry.config) == "function", "completion spec config must be a function")

local config_ok, config_err = pcall(entry.config, entry, entry.opts or {})
test("completion config() executes without error", function()
  if not config_ok then error("config() failed: " .. tostring(config_err)) end
end)

test("cmp.setup was called", function()
  assert_true(#cmp_setup_calls >= 1, "cmp.setup should be called at least once")
end)

-- First cmp.setup call is the main insert-mode setup
local opts = cmp_setup_calls[1]

test("cmp.setup received an opts table", function()
  assert_true(type(opts) == "table", "opts must be a table")
end)

test("cmp.setup opts.sources contains nvim_lsp, lazydev, luasnip, buffer, path", function()
  local sources = opts.sources
  assert_true(type(sources) == "table", "opts.sources must be a table")
  local names = {}
  for _, s in ipairs(sources) do
    if s.name then names[s.name] = true end
  end
  local required = { "nvim_lsp", "lazydev", "luasnip", "buffer", "path" }
  for _, n in ipairs(required) do
    assert_true(names[n], "Source '" .. n .. "' missing from cmp.setup opts.sources")
  end
end)

test("lazydev source has group_index = 0 (higher priority)", function()
  for _, s in ipairs(opts.sources) do
    if s.name == "lazydev" then
      assert_eq(s.group_index, 0, "lazydev source should have group_index 0")
      return
    end
  end
  error("lazydev source not found")
end)

test("buffer source uses keyword_length >= 3", function()
  for _, s in ipairs(opts.sources) do
    if s.name == "buffer" then
      assert_true(type(s.keyword_length) == "number" and s.keyword_length >= 3,
        "buffer source should have keyword_length >= 3")
      return
    end
  end
  error("buffer source not found")
end)

test("<C-;> is present in opts.mapping (intentional completion keybind)", function()
  local mapping = opts.mapping
  assert_true(type(mapping) == "table", "opts.mapping must be a table")
  assert_true(mapping["<C-;>"] ~= nil,
    "<C-;> must be present in cmp mapping (per user memory: do not change to <C-Space>)")
end)

test("<C-Space> is NOT silently used in place of <C-;>", function()
  -- Defensive: ensure <C-Space> isn't mapped to cmp.complete — the user
  -- memory explicitly says "don't change to <C-Space>".
  local mapping = opts.mapping
  if mapping["<C-Space>"] ~= nil then
    error("<C-Space> should NOT be mapped — user prefers <C-;> for cmp.complete")
  end
end)

test("opts.mapping includes <CR> confirm, <Tab>, <S-Tab>", function()
  local mapping = opts.mapping
  for _, key in ipairs({ "<CR>", "<Tab>", "<S-Tab>" }) do
    assert_true(mapping[key] ~= nil, key .. " missing from cmp mapping")
  end
end)

test("opts.snippet.expand is configured", function()
  assert_true(type(opts.snippet) == "table" and type(opts.snippet.expand) == "function",
    "opts.snippet.expand must be a function")
end)

test("cmp.setup.cmdline was called for ':' and '/'", function()
  local channels = {}
  for _, c in ipairs(cmp_cmdline_setup_calls) do
    channels[c.channel] = true
  end
  assert_true(channels[":"], "cmp.setup.cmdline(':', ...) should be called")
  assert_true(channels["/"], "cmp.setup.cmdline('/', ...) should be called")
end)

-- ============================================================================
-- Cleanup
-- ============================================================================

package.preload["cmp"] = nil
package.preload["luasnip"] = nil
package.preload["luasnip.loaders.from_vscode"] = nil
package.preload["luasnip.loaders.from_lua"] = nil
package.preload["cmp_luasnip"] = nil
package.loaded["cmp"] = nil
package.loaded["luasnip"] = nil
package.loaded["luasnip.loaders.from_vscode"] = nil
package.loaded["luasnip.loaders.from_lua"] = nil
package.loaded["cmp_luasnip"] = nil
package.loaded["plugins.completion"] = nil

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
