-- nvim-luapad — live-evaluating Lua scratchpad
-- Runs in the *current* Neovim runtime: code is re-evaluated as you type and
-- results appear inline as virtual text. Handy for poking at plugin configs,
-- vim.* values, and your own utils.* modules without an enter-to-submit step.
return {
  "rafcamlet/nvim-luapad",
  lazy = true,
  cmd = { "Luapad", "LuaRun", "Lua" },
  config = function()
    require("luapad").setup({
      count_limit = 150000,
      error_indicator = true,
      eval_on_move = true,
      error_highlight = "WarningMsg",
      on_init = function()
        -- expose vim.inspect as `p` inside the scratchpad for quick dumps
        return { p = vim.inspect }
      end,
    })
  end,
  keys = {
    { "<leader>rl", "<cmd>Luapad<cr>", desc = "Luapad scratchpad (live eval)" },
  },
}
