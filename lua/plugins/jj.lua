-- Jujutsu VCS Integration (jj.nvim)
-- Always loaded - commands available everywhere (gracefully fails in non-jj repos)
--
-- Commands: :J status, :J log, :J describe, :J new, :J edit, :J diff, :J squash
-- Functions: require("jj").status(), .log(), .describe(), .new(), etc.
-- Pickers: require("jj.picker").status, .file_history (with Snacks.nvim)

return {
  {
    "nicolasgb/jj.nvim",
    lazy = false,  -- Always loaded (commands available in any directory)
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",  -- Optional: For picker integration
    },
    config = function()
      -- Check if jj binary is available
      if vim.fn.executable("jj") == 0 then
        vim.notify(
          "jj binary not found in PATH. Install Jujutsu to use jj.nvim features.",
          vim.log.levels.WARN
        )
        -- Don't fail setup - just warn
      end
      
      require("jj").setup({
        -- Editor mode for jj describe
        -- "buffer" = full editor with syntax highlighting
        -- "input" = single-line prompt
        describe_editor = "buffer",
        
        -- Snacks.nvim picker integration
        picker = {
          snacks = {
            -- Options passed to Snacks.nvim picker
            -- Will automatically use Snacks if available
          },
        },
        
        -- Custom highlights for file status (match tokyonight theme)
        highlights = {
          added = { fg = "#9ece6a" },      -- tokyonight green
          modified = { fg = "#e0af68" },   -- tokyonight yellow
          deleted = { fg = "#f7768e" },    -- tokyonight red
          renamed = { fg = "#7aa2f7" },    -- tokyonight blue
        },
      })
      
      -- Create user commands for convenience (in addition to :J command)
      local jj = require("jj")
      
      vim.api.nvim_create_user_command("JJStatus", function()
        jj.status()
      end, { desc = "Jujutsu status" })
      
      vim.api.nvim_create_user_command("JJLog", function()
        jj.log()
      end, { desc = "Jujutsu log" })
      
      vim.api.nvim_create_user_command("JJDescribe", function()
        jj.describe()
      end, { desc = "Jujutsu describe (edit change description)" })
      
      vim.api.nvim_create_user_command("JJNew", function()
        jj.new()
      end, { desc = "Jujutsu new (create new change)" })
      
      vim.api.nvim_create_user_command("JJEdit", function()
        jj.edit()
      end, { desc = "Jujutsu edit (edit existing change)" })
      
      vim.api.nvim_create_user_command("JJDiff", function()
        jj.diff()
      end, { desc = "Jujutsu diff" })
      
      vim.api.nvim_create_user_command("JJSquash", function()
        jj.squash()
      end, { desc = "Jujutsu squash (squash diff to parent)" })
      
      -- Picker commands (if available)
      local picker_ok, picker = pcall(require, "jj.picker")
      if picker_ok then
        vim.api.nvim_create_user_command("JJPickerStatus", function()
          picker.status()
        end, { desc = "Jujutsu picker: select changed files" })
        
        vim.api.nvim_create_user_command("JJPickerHistory", function()
          picker.file_history()
        end, { desc = "Jujutsu picker: file history" })
      end
      
      -- Optional: Add highlight groups for better integration
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          -- Refresh jj highlights when colorscheme changes
          local colors = require("jj").setup().highlights or {}
          for status, color in pairs(colors) do
            if color.fg then
              vim.api.nvim_set_hl(0, "JJ" .. status:gsub("^%l", string.upper), color)
            end
          end
        end,
      })
    end,
  },
}
