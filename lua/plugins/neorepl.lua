-- neorepl.nvim — in-process Lua/Vim REPL buffer
-- Runs in the *current* Neovim runtime, so it can introspect loaded
-- plugins, package.loaded, lazy.nvim specs, and your own utils.* modules.
-- Enter-to-submit prompt with history + completion; switch between Lua and
-- Vim command modes inside the same buffer.
return {
  "ii14/neorepl.nvim",
  lazy = true,
  cmd = "Repl",
  config = function()
    -- Open a scratch REPL buffer in a horizontal split.
    vim.api.nvim_create_user_command("Repl", function()
      vim.cmd("botright split")
      vim.cmd("enew")
      require("neorepl").new({
        lang = "lua",
        buffer = 0,
        window = 0,
      })
      vim.cmd("resize 15")
    end, { desc = "Open a neorepl Lua/Vim REPL (current runtime)" })
  end,
  keys = {
    { "<leader>rr", "<cmd>Repl<cr>", desc = "REPL (neorepl, current runtime)" },
  },
}
