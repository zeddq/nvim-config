-- Context-Aware VCS Keybindings
-- Unified keybindings that work for both Git and Jujutsu repositories
-- Automatically detects VCS type and executes appropriate command
--
-- Keybinding Philosophy:
-- - Same keys work in git and jj repos (context-aware)
-- - Clear error messages when commands unavailable
-- - Git commands as fallback where sensible
-- - Jj-specific operations use separate keys

return {
  {
    name = "vcs-keymaps",
    dir = vim.fn.stdpath("config") .. "/lua/plugins",
    lazy = false,  -- Load immediately (keybindings available everywhere)
    priority = 50,  -- Load after neo-tree but before user interaction

    config = function()
      local vcs = require("utils.vcs")

      ---Execute command based on VCS type
      ---@param git_cmd string|function Git command or function
      ---@param jj_cmd string|function Jujutsu command or function
      ---@param opts table|nil Optional configuration
      local function exec_vcs_cmd(git_cmd, jj_cmd, opts)
        opts = opts or {}

        -- Detect VCS type with error handling
        local ok, vcs_type = pcall(function()
          return vcs.detect_vcs_type()
        end)

        if not ok then
          vim.notify("Failed to detect VCS type: " .. tostring(vcs_type), vim.log.levels.ERROR)
          return
        end

        -- Handle non-repo case
        if vcs_type == "none" then
          vim.notify("Not in a VCS repository", vim.log.levels.WARN)
          return
        end

        -- Select appropriate command
        local cmd = (vcs_type == "git") and git_cmd or jj_cmd

        -- Execute with error handling
        local exec_ok, err = pcall(function()
          if type(cmd) == "function" then
            cmd()
          else
            vim.cmd(cmd)
          end
        end)

        if not exec_ok then
          vim.notify(
            string.format("[%s] Command failed: %s", vcs_type:upper(), err),
            vim.log.levels.ERROR
          )
        end
      end

      ---Run VCS command in terminal split
      ---@param cmd string Shell command to run
      local function run_terminal(cmd)
        vim.cmd("belowright 15split | terminal " .. cmd)
        vim.cmd("startinsert")
      end

      ---Check if we're in a jj repository
      ---@return boolean
      local function is_jj_repo()
        return vcs.detect_vcs_type() == "jj"
      end

      -- ========================================================================
      -- FILE EXPLORER (VCS-Aware)
      -- ========================================================================

      vim.keymap.set("n", "<leader>e", function()
        -- Neo-tree works for both git and jj (no special handling needed)
        require("neo-tree.command").execute({ toggle = true })
      end, { desc = "Toggle File Explorer (VCS-aware)" })

      -- ========================================================================
      -- VCS STATUS & INFO
      -- ========================================================================

      vim.keymap.set("n", "<leader>gs", function()
        exec_vcs_cmd(
          function() run_terminal("git status") end,
          function()
            -- jj.nvim uses :J command interface
            vim.cmd("J status")
          end
        )
      end, { desc = "VCS Status" })

      vim.keymap.set("n", "<leader>gl", function()
        exec_vcs_cmd(
          function() run_terminal("git log --oneline --graph --decorate --all -20") end,
          function()
            vim.cmd("J log")
          end
        )
      end, { desc = "VCS Log" })

      vim.keymap.set("n", "<leader>gd", function()
        exec_vcs_cmd(
          function() run_terminal("git diff") end,
          function()
            vim.cmd("J diff")
          end
        )
      end, { desc = "VCS Diff" })

      vim.keymap.set("n", "<leader>gb", function()
        exec_vcs_cmd(
          function() run_terminal("git blame " .. vim.fn.expand("%")) end,
          function()
            -- jj doesn't have built-in blame, use git blame as fallback
            vim.notify("jj doesn't have blame, using git blame", vim.log.levels.INFO)
            run_terminal("git blame " .. vim.fn.expand("%"))
          end
        )
      end, { desc = "VCS Blame" })

      -- ========================================================================
      -- COMMIT/DESCRIBE OPERATIONS
      -- ========================================================================

      vim.keymap.set("n", "<leader>gc", function()
        exec_vcs_cmd(
          function() run_terminal("git commit") end,
          function()
            vim.cmd("J describe")
          end
        )
      end, { desc = "VCS Commit/Describe" })

      vim.keymap.set("n", "<leader>gC", function()
        exec_vcs_cmd(
          function() run_terminal("git commit --amend") end,
          function()
            -- In jj, just describe again (it's always amending the current change)
            vim.cmd("J describe")
          end
        )
      end, { desc = "VCS Amend/Redescribe" })

      -- ========================================================================
      -- BRANCH/BOOKMARK MANAGEMENT
      -- ========================================================================

      vim.keymap.set("n", "<leader>gB", function()
        exec_vcs_cmd(
          function()
            vim.ui.input({ prompt = "Branch name: " }, function(input)
              if input and input ~= "" then
                run_terminal("git checkout -b " .. input)
              end
            end)
          end,
          function()
            vim.ui.input({ prompt = "Bookmark name: " }, function(input)
              if input and input ~= "" then
                run_terminal("jj bookmark create " .. input)
              end
            end)
          end
        )
      end, { desc = "Create Branch/Bookmark" })

      vim.keymap.set("n", "<leader>gL", function()
        exec_vcs_cmd(
          function() run_terminal("git branch -avv") end,
          function() run_terminal("jj bookmark list") end
        )
      end, { desc = "List Branches/Bookmarks" })

      -- ========================================================================
      -- REMOTE OPERATIONS
      -- ========================================================================

      vim.keymap.set("n", "<leader>gp", function()
        exec_vcs_cmd(
          function() run_terminal("git push") end,
          function() run_terminal("jj git push") end
        )
      end, { desc = "VCS Push" })

      vim.keymap.set("n", "<leader>gP", function()
        exec_vcs_cmd(
          function() run_terminal("git pull") end,
          function() run_terminal("jj git fetch") end
        )
      end, { desc = "VCS Pull/Fetch" })

      vim.keymap.set("n", "<leader>gf", function()
        exec_vcs_cmd(
          function() run_terminal("git fetch") end,
          function() run_terminal("jj git fetch") end
        )
      end, { desc = "VCS Fetch" })

      -- ========================================================================
      -- JUJUTSU-SPECIFIC OPERATIONS
      -- ========================================================================
      -- These operations only work in jj repos

      vim.keymap.set("n", "<leader>gn", function()
        if is_jj_repo() then
          vim.cmd("J new")
        else
          vim.notify("jj new is only available in Jujutsu repositories", vim.log.levels.WARN)
        end
      end, { desc = "JJ New (jj only)" })

      vim.keymap.set("n", "<leader>gS", function()
        if is_jj_repo() then
          vim.cmd("J squash")
        else
          vim.notify("jj squash is only available in Jujutsu repositories", vim.log.levels.WARN)
        end
      end, { desc = "JJ Squash (jj only)" })

      vim.keymap.set("n", "<leader>ge", function()
        if is_jj_repo() then
          vim.cmd("J edit")
        else
          vim.notify("jj edit is only available in Jujutsu repositories", vim.log.levels.WARN)
        end
      end, { desc = "JJ Edit (jj only)" })

      -- ========================================================================
      -- PICKERS (if available)
      -- ========================================================================

      vim.keymap.set("n", "<leader>gj", function()
        if is_jj_repo() then
          local picker_ok, picker = pcall(require, "jj.picker")
          if picker_ok and picker.status then
            picker.status()
          else
            vim.notify("jj.nvim picker not available", vim.log.levels.WARN)
          end
        else
          vim.notify("JJ picker is only available in Jujutsu repositories", vim.log.levels.WARN)
        end
      end, { desc = "JJ Picker: Status (jj only)" })

      vim.keymap.set("n", "<leader>gh", function()
        if is_jj_repo() then
          local picker_ok, picker = pcall(require, "jj.picker")
          if picker_ok and picker.file_history then
            picker.file_history()
          else
            vim.notify("jj.nvim picker not available", vim.log.levels.WARN)
          end
        else
          -- In git repos, could use telescope git_bcommits as equivalent
          local telescope_ok, telescope = pcall(require, "telescope.builtin")
          if telescope_ok then
            telescope.git_bcommits()
          else
            vim.notify("File history not available", vim.log.levels.WARN)
          end
        end
      end, { desc = "File History (VCS-aware)" })

      -- ========================================================================
      -- UTILITY COMMANDS
      -- ========================================================================

      vim.keymap.set("n", "<leader>gR", function()
        vcs.clear_cache()
        vim.notify("VCS cache cleared - VCS type will be re-detected", vim.log.levels.INFO)
      end, { desc = "Refresh VCS Cache" })

      vim.keymap.set("n", "<leader>g?", function()
        local vcs_type = vcs.detect_vcs_type()
        local root = vcs.get_repo_root()
        local stats = vcs.get_cache_stats()

        local msg = string.format(
          "VCS Information:\n" ..
          "  Type: %s\n" ..
          "  Root: %s\n" ..
          "  Cache: %d entries (%d valid, %d expired)",
          vcs_type,
          root or "none",
          stats.total_entries,
          stats.valid_entries,
          stats.expired_entries
        )

        vim.notify(msg, vim.log.levels.INFO)
      end, { desc = "VCS Info" })

      -- ========================================================================
      -- AUTOCMDS FOR CACHE MANAGEMENT
      -- ========================================================================

      -- Clear cache when changing directories
      vim.api.nvim_create_autocmd("DirChanged", {
        callback = function()
          vcs.clear_cache()
        end,
        desc = "Clear VCS cache on directory change",
      })

      -- Optional: Show VCS type in command line when entering buffer
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          if vcs.debug then
            local vcs_type = vcs.get_cached_vcs_type() or vcs.detect_vcs_type()
            print(string.format("[VCS] Buffer in %s repo", vcs_type))
          end
        end,
        desc = "Debug: Show VCS type on buffer enter",
      })
    end,
  },
}
