-- Neovim Lua development support
-- Provides full vim.* API recognition, go-to-definition, hover docs, and completions
-- Automatically configures lua_ls workspace libraries based on require() calls

return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    dependencies = {
      -- Type stubs for vim.uv (libuv bindings)
      { "Bilal2453/luvit-meta", lazy = true },
    },
    opts = {
      library = {
        -- Load luvit types when vim.uv is referenced
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
}
