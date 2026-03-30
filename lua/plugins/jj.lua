---@diagnostic disable: undefined-field
-- Jujutsu VCS Integration (jj.nvim)
-- Always loaded - commands available everywhere (gracefully fails in non-jj repos)
--
-- Commands: :J status, :J log, :J describe, :J new, :J edit, :J diff, :J squash
-- Functions: require("jj").status(), .log(), .describe(), .new(), etc.
-- Pickers: require("jj.picker").status, .file_history (with Snacks.nvim)
return {
  "nicolasgb/jj.nvim",
  dependencies = {
    "folke/snacks.nvim", -- Optional only if you use picker's
  },

  config = function()
    local jj = require("jj")
    jj.setup({
      -- Setup snacks as a picker
      picker = {
        -- Here you can pass the options as you would for snacks.
        -- It will be used when using the picker
        snacks = {},
      },

      -- Customize syntax highlighting colors for the describe buffer
      highlights = {
        modified = { fg = "#89ddff", bold = true },
        added = { fg = "#c3e88d", ctermfg = "LightGreen" },
        deleted = { fg = "#f85149", ctermfg = "Red" }, -- Deleted files
        renamed = { fg = "#d29922", ctermfg = "Yellow" }, -- Renamed files
      },

      -- Configure terminal behavior
      terminal = {
        -- Cursor render delay in milliseconds (default: 10)
        -- If cursor column is being reset to 0 when refreshing commands, try increasing this value
        -- This delay allows the terminal emulator to complete rendering before restoring cursor position
        cursor_render_delay = 10,
      },

      -- Configure cmd module (describe editor, keymaps)
      cmd = {
        -- Configure describe editor
        describe = {
          editor = {
            -- Choose the editor mode for describe command
            -- "buffer" - Opens a Git-style commit message buffer with syntax highlighting (default)
            -- "input" - Uses a simple vim.ui.input prompt
            type = "buffer",
            -- Customize keymaps for the describe editor buffer
            keymaps = {
              close = { "<Esc>", "<C-c>", "q" }, -- Keys to close editor without saving
            },
          },
        },

        -- Configure log command behavior
        log = {
          close_on_edit = false, -- Close log buffer after editing a change
        },

        -- Configure bookmark command
        bookmark = {
          prefix = "",
        },

        -- Configure keymaps for command buffers
        keymaps = {
          -- Log buffer keymaps (set to nil to disable)
          log = {
            checkout = "<CR>", -- Edit revision under cursor
            checkout_immutable = "<S-CR>", -- Edit revision (ignore immutability)
            describe = "d", -- Describe revision under cursor
            diff = "<S-d>", -- Diff revision under cursor
            edit = "e", -- Edit revision under cursor
            new = "n", -- Create new change branching off
            new_after = "<C-n>", -- Create new change after revision
            new_after_immutable = "<S-n>", -- Create new change after (ignore immutability)
            undo = "<S-u>", -- Undo last operation
            redo = "<S-r>", -- Redo last undone operation
            abandon = "a", -- Abandon revision under cursor
            bookmark = "b", -- Create or move bookmark to revision under cursor
            fetch = "f", -- Fetch from remote
            push = "p", -- Push bookmark of revision under cursor
            push_all = "<S-p>", -- Push all changes to remote
            open_pr = "o", -- Open PR/MR for revision under cursor
            open_pr_list = "<S-o>", -- Open PR/MR by selecting from all bookmarks
          },
          -- Status buffer keymaps (set to nil to disable)
          status = {
            open_file = "<CR>", -- Open file under cursor
            restore_file = "<S-x>", -- Restore file under cursor
          },
          -- Close keymaps (shared across all buffers)
          close = { "q", "<Esc>" },
        },
      },
    })

    local cmd = require("jj.cmd")
    vim.keymap.set("n", "<leader>jd", cmd.describe, { desc = "JJ describe" })
    vim.keymap.set("n", "<leader>jl", cmd.log, { desc = "JJ log" })
    vim.keymap.set("n", "<leader>je", cmd.edit, { desc = "JJ edit" })
    vim.keymap.set("n", "<leader>jn", cmd.new, { desc = "JJ new" })
    vim.keymap.set("n", "<leader>js", cmd.status, { desc = "JJ status" })
    vim.keymap.set("n", "<leader>sj", cmd.squash, { desc = "JJ squash" })
    vim.keymap.set("n", "<leader>ju", cmd.undo, { desc = "JJ undo" })
    vim.keymap.set("n", "<leader>jy", cmd.redo, { desc = "JJ redo" })
    vim.keymap.set("n", "<leader>jr", cmd.rebase, { desc = "JJ rebase" })
    vim.keymap.set("n", "<leader>jbc", cmd.bookmark_create, { desc = "JJ bookmark create" })
    vim.keymap.set("n", "<leader>jbd", cmd.bookmark_delete, { desc = "JJ bookmark delete" })
    vim.keymap.set("n", "<leader>jbm", cmd.bookmark_move, { desc = "JJ bookmark move" })
    vim.keymap.set("n", "<leader>ja", cmd.abandon, { desc = "JJ abandon" })
    vim.keymap.set("n", "<leader>jf", cmd.fetch, { desc = "JJ fetch" })
    vim.keymap.set("n", "<leader>jp", cmd.push, { desc = "JJ push" })
    vim.keymap.set("n", "<leader>jpr", cmd.open_pr, { desc = "JJ open PR from bookmark in current revision or parent" })
    vim.keymap.set("n", "<leader>jpl", function()
      cmd.open_pr({ list_bookmarks = true })
    end, { desc = "JJ open PR listing available bookmarks" })

    -- Diff commands
    local diff = require("jj.diff")
    vim.keymap.set("n", "<leader>df", function()
      diff.open_vdiff()
    end, { desc = "JJ diff current buffer" })
    vim.keymap.set("n", "<leader>dF", function()
      diff.open_hsplit()
    end, { desc = "JJ hdiff current buffer" })

    -- cmd.diff (uses jj.diff module with revision view)
    vim.keymap.set("n", "<leader>dd", cmd.diff, { desc = "JJ diff revision" })
    vim.keymap.set("n", "<leader>dD", function()
      cmd.diff({ current = true })
    end, { desc = "JJ diff current file (buffer)" })

    -- Terminal diff (jj diff in terminal)
    if cmd.cezdiff then
      vim.keymap.set("n", "<leader>dj", cmd.cezdiff, { desc = "JJ diff (terminal)" })
      vim.keymap.set("n", "<leader>dJ", function()
        cmd.cezdiff({ current = true })
      end, { desc = "JJ diff current file (terminal)" })
    end


    -- Pickers
    local picker = require("jj.picker")
    vim.keymap.set("n", "<leader>gj", function()
      picker.status()
    end, { desc = "JJ Picker status" })
    vim.keymap.set("n", "<leader>jgh", function()
      picker.file_history()
    end, { desc = "JJ Picker history" })

    -- Some functions like `log` can take parameters
    vim.keymap.set("n", "<leader>jL", function()
      cmd.log({
        revisions = "'all()'", -- equivalent to jj log -r ::
      })
    end, { desc = "JJ log all" })

    -- This is an alias i use for moving bookmarks its so good
    vim.keymap.set("n", "<leader>jt", function()
      cmd.j("tug")
      cmd.log({})
    end, { desc = "JJ tug" })
  end,

  -- Core commands
}

--local old = {
--  {
--    "nicolasgb/jj.nvim",
--    lazy = false, -- Always loaded (commands available in any directory)
--    dependencies = {
--      "folke/snacks.nvim", -- Required for picker integration
--    },
--    config = function()
--      require("jj").setup({
--        -- Editor mode for jj describe
--        -- "buffer" = full editor with syntax highlighting
--        -- "input" = single-line prompt
--        describe_editor = "buffer",
--
--        -- Picker integration
--        -- jj.nvim currently supports Snacks picker
--        picker = {
--          snacks = {},
--        },
--
--        -- Custom highlights for file status (match tokyonight theme)
--        highlights = {
--          added = { fg = "#9ece6a" }, -- tokyonight green
--          modified = { fg = "#e0af68" }, -- tokyonight yellow
--          deleted = { fg = "#f7768e" }, -- tokyonight red
--          renamed = { fg = "#7aa2f7" }, -- tokyonight blue
--        },
--      })
--
--      -- Create user commands for convenience (in addition to :J command)
--      local cmd = require("jj.cmd")
--
--      vim.api.nvim_create_user_command("JJStatus", function()
--        cmd.status()
--      end, { desc = "Jujutsu status" })
--
--      vim.api.nvim_create_user_command("JJLog", function()
--        cmd.log()
--      end, { desc = "Jujutsu log" })
--
--      vim.api.nvim_create_user_command("JJDescribe", function()
--        cmd.describe()
--      end, { desc = "Jujutsu describe (edit change description)" })
--
--      vim.api.nvim_create_user_command("JJNew", function()
--        cmd.new()
--      end, { desc = "Jujutsu new (create new change)" })
--
--      vim.api.nvim_create_user_command("JJEdit", function()
--        cmd.edit()
--      end, { desc = "Jujutsu edit (edit existing change)" })
--
--      vim.api.nvim_create_user_command("JJDiff", function()
--        cmd.diff()
--      end, { desc = "Jujutsu diff" })
--
--      vim.api.nvim_create_user_command("JJSquash", function()
--        cmd.squash()
--      end, { desc = "Jujutsu squash (squash diff to parent)" })
--
--      -- Picker commands (if available)
--      local picker_ok, picker = pcall(require, "jj.picker")
--      if picker_ok then
--        vim.api.nvim_create_user_command("JJPickerStatus", function()
--          picker.status()
--        end, { desc = "Jujutsu picker: select changed files" })
--
--        vim.api.nvim_create_user_command("JJPickerHistory", function()
--          picker.file_history()
--        end, { desc = "Jujutsu picker: file history" })
--      end
--
--      -- Optional: Add highlight groups for better integration
--      local highlight_colors = {
--        added = { fg = "#9ece6a" },
--        modified = { fg = "#e0af68" },
--        deleted = { fg = "#f7768e" },
--        renamed = { fg = "#7aa2f7" },
--      }
--
--      vim.api.nvim_create_autocmd("ColorScheme", {
--        pattern = "*",
--        callback = function()
--          -- Refresh jj highlights when colorscheme changes
--          for status, color in pairs(highlight_colors) do
--            if color.fg then
--              vim.api.nvim_set_hl(0, "JJ" .. status:gsub("^%l", string.upper), color)
--            end
--          end
--        end,
--      })
--    end,
--  },
--}
--
