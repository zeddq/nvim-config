-- Claude Code AI Assistant Integration
-- Seamless integration of Claude Code CLI with Neovim
--
-- Repository: https://github.com/greggh/claude-code.nvim
-- Dependencies: plenary.nvim (shared with neo-tree)
--
-- Features:
-- - Floating window interface (non-intrusive)
-- - Auto-reload files modified by Claude Code
-- - Git repository detection (compatible with jj/git workflow)
-- - Notifications via snacks.nvim
-- - which-key integration for discoverability
--
-- Commands:
-- - :ClaudeCode - Toggle Claude Code terminal
-- - :ClaudeCodeContinue - Resume last conversation
-- - :ClaudeCodeResume - Pick from saved conversations
-- - :ClaudeCodeVerbose - Launch with detailed logging
--
-- Keybindings (no conflicts detected):
-- - <C-,> - Primary toggle (normal/terminal mode)
-- - <leader>cc - Alternative toggle
-- - <leader>cC - Continue conversation
-- - <leader>cr - Resume conversation picker
-- - <leader>cv - Verbose mode

return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Already installed via neo-tree (git operations)
  },
  -- Lazy-load on command or keybinding for optimal startup time
  cmd = { "ClaudeCode", "ClaudeCodeContinue", "ClaudeCodeResume", "ClaudeCodeVerbose" },
  keys = {
    { "<C-,>", desc = "Toggle Claude Code" },
    { "<leader>cc", desc = "Toggle Claude Code" },
    { "<leader>cC", desc = "Continue conversation" },
    { "<leader>cr", desc = "Resume conversation (picker)" },
    { "<leader>cv", desc = "Verbose mode" },
  },
  config = function()
    require("claude-code").setup({
      -- ========================================================================
      -- COMMAND CONFIGURATION
      -- ========================================================================
      -- Use full claudep alias arguments for plugins and permissions
      command = "claude --dangerously-skip-permissions "
        .. "--plugin-dir ~/.claude/plugins/local/jj-vcs "
        .. "--plugin-dir ~/.claude/plugins/local/lyra-ultra "
        .. "--plugin-dir ~/.claude/plugins/local/andrej-karpathy-skills",

      -- ========================================================================
      -- WINDOW CONFIGURATION
      -- ========================================================================
      window = {
        -- Floating window for non-intrusive experience
        position = "float",           -- Options: "float", "botright", "topleft", "vertical"
        
        -- Terminal behavior
        enter_insert = true,          -- Auto-enter insert mode on launch
        hide_numbers = true,          -- Clean terminal: no line numbers
        hide_signcolumn = true,       -- Clean terminal: no sign column
        
        -- Float-specific settings (only applies when position = "float")
        float = {
          width = "80%",              -- 80% of editor width (can be number or percentage)
          height = "80%",             -- 80% of editor height (can be number or percentage)
          row = "center",             -- Vertical position: "center", number, or percentage
          col = "center",             -- Horizontal position: "center", number, or percentage
          relative = "editor",        -- Position relative to: "editor" or "cursor"
          border = "rounded",         -- Border style: "rounded" matches neo-tree/telescope theme
                                      -- Options: "none", "single", "double", "rounded", "solid", "shadow"
        },
      },
      
      -- ========================================================================
      -- FILE REFRESH CONFIGURATION
      -- ========================================================================
      -- Auto-reload files modified by Claude Code
      -- Integrates with Neovim's buffer system (no conflicts with existing watchers)
      refresh = {
        enable = true,                -- Enable automatic file change detection
        updatetime = 100,             -- Polling interval when active (milliseconds)
                                      -- Lower = more responsive, higher = less CPU usage
        timer_interval = 1000,        -- File check frequency (milliseconds)
        show_notifications = true,    -- Display reload notifications (uses snacks.nvim if available)
      },
      
      -- ========================================================================
      -- GIT INTEGRATION
      -- ========================================================================
      -- Compatible with existing jj/git VCS utilities in utils/vcs.lua
      git = {
        use_git_root = true,          -- Auto-detect repository root and set as working directory
                                      -- Works with both git and jj repositories
      },
      
      -- ========================================================================
      -- KEYBINDINGS
      -- ========================================================================
      -- All keybindings verified conflict-free with existing configuration
      -- Current keybinding landscape:
      --   <leader>e  - neo-tree
      --   <leader>f* - telescope
      --   <leader>g* - VCS operations
      --   <leader>h* - gitsigns hunks
      --   <leader>s* - snacks utilities
      --   <leader>c* - AVAILABLE (claude-code)
      keymaps = {
        toggle = {
          normal = "<C-,>",           -- Primary toggle in normal mode
          terminal = "<C-,>",         -- Toggle from within Claude Code terminal
          variants = {
            continue = "<leader>cC",  -- Resume last conversation (uppercase C)
            verbose = "<leader>cv",   -- Launch with verbose output
          },
        },
        -- Terminal navigation features
        window_navigation = true,     -- Enable <C-h/j/k/l> for window movement
        scrolling = true,             -- Enable <C-f/b> for page scrolling
      },
    })
    
    -- ========================================================================
    -- ADDITIONAL KEYBINDINGS (consistent with config style)
    -- ========================================================================
    
    -- Alternative toggle using <leader>cc (more discoverable via which-key)
    vim.keymap.set('n', '<leader>cc', ':ClaudeCode<CR>', {
      desc = 'Toggle Claude Code',
      silent = true,
    })
    
    -- Resume conversation picker (not in plugin defaults)
    vim.keymap.set('n', '<leader>cr', ':ClaudeCodeResume<CR>', {
      desc = 'Resume conversation (picker)',
      silent = true,
    })
    
    -- ========================================================================
    -- SNACKS.NVIM INTEGRATION (optional enhancement)
    -- ========================================================================
    -- Integrate Claude Code file reload events with snacks.nvim notifier
    -- Gracefully falls back if snacks is not available
    
    vim.api.nvim_create_autocmd("User", {
      pattern = "ClaudeCodeFileReloaded",
      callback = function(event)
        -- Check if snacks.nvim is available
        if package.loaded.snacks and Snacks.notifier then
          -- Show notification with file path (relative to cwd)
          local file_path = event.file or "unknown"
          local rel_path = vim.fn.fnamemodify(file_path, ":.")
          
          Snacks.notifier.notify(
            string.format("File reloaded: %s", rel_path),
            "info",
            {
              title = "Claude Code",
              timeout = 2000,  -- 2 second display
            }
          )
        end
      end,
      desc = "Notify on Claude Code file reload (snacks.nvim integration)",
    })
    
    -- ========================================================================
    -- AUTOCMD FOR TERMINAL FILETYPE
    -- ========================================================================
    -- Set proper filetype for Claude Code terminal buffer
    -- Useful for custom highlighting or terminal-specific settings
    
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*",
      callback = function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname:match("claude") or bufname:match("ClaudeCode") then
          vim.bo.filetype = "claudecode"
          
          -- Optional: Add terminal-specific settings here
          -- Example: vim.wo.number = false
        end
      end,
      desc = "Set filetype for Claude Code terminal",
    })
  end,
}
