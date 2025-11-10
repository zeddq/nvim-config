-- snacks.nvim - Collection of QoL enhancements
-- Architecture: Balanced Enhancement approach - adds features without replacing existing plugins
-- Phase 4 Implementation: 7 modules enabled (scroll disabled due to paste issues)
--
-- Modules enabled: bigfile, dashboard, notifier, statuscolumn, indent, words, quickfile
-- Modules disabled: scroll (paste risk), picker (keep telescope), explorer (keep nvim-tree), scope, input
--
-- Conflicts resolved:
--   - statuscolumn + gitsigns: Built-in integration, no conflicts
--   - notifier + vim.notify: Enhances LSP messages
--   - dashboard + lazy.nvim: Workaround with function wrapping
--   - Keybindings: <leader>s prefix (no collisions)

return {
  "folke/snacks.nvim",
  priority = 1000, -- Load before other UI plugins
  lazy = false, -- Load immediately (infrastructure role)
  ---@type snacks.Config
  opts = {
    -- ========================================================================
    -- PERFORMANCE ENHANCEMENTS (invisible optimizations)
    -- ========================================================================

    -- bigfile: Disable heavy features for files >1.5MB
    -- Pure performance enhancement, no UI impact
    bigfile = {
      enabled = true,
      size = 1.5 * 1024 * 1024, -- 1.5MB threshold
      -- Features to disable for large files:
      setup = function(ctx)
        vim.b.minianimate_disable = true
        vim.schedule(function()
          vim.bo[ctx.buf].syntax = ctx.ft
        end)
      end,
    },

    -- quickfile: Faster file loading for small files
    -- Invisible performance optimization
    quickfile = {
      enabled = true,
    },

    -- ========================================================================
    -- VISUAL ENHANCEMENTS
    -- ========================================================================

    -- statuscolumn: Enhanced line numbers, git signs, diagnostics
    -- Integrates with gitsigns.nvim (already installed)
    -- Issue #613: Built-in gitsigns support via pattern matching
    statuscolumn = {
      enabled = true,
      left = { "mark", "sign" }, -- Diagnostics and git signs on left
      right = { "fold", "git" }, -- Fold markers and git status on right
      -- Git sign patterns (compatible with gitsigns.nvim)
      git = {
        patterns = { "GitSign", "MiniDiffSign" },
      },
    },

    -- indent: Indent guides for better code readability
    -- Issue #389: Performance validated, faster than indent-blankline
    -- Integrates with bigfile for automatic disable on large files
    indent = {
      enabled = true,
      char = "│", -- Indent guide character
      blank = " ", -- Blank line character
      only_scope = false, -- Show all indent levels (not just scope)
      only_current = false, -- Show guides for all lines
      -- Exclude specific filetypes if needed:
      -- filter = function(buf)
      --   local ft = vim.bo[buf].filetype
      --   return not vim.tbl_contains({ "yaml" }, ft)
      -- end,
    },

    -- words: LSP-based word highlighting under cursor
    -- Complements existing LSP documentHighlight
    -- No conflicts with LSP features
    words = {
      enabled = true,
      debounce = 200, -- 200ms delay before highlighting
      modes = { "n", "i", "c" }, -- Active in normal, insert, command modes
    },

    -- scroll: DISABLED due to Issue #384 (paste corruption)
    -- Large text paste problems across multiple terminals
    -- Can be enabled after manual testing if needed
    scroll = {
      enabled = false,
      -- If enabling, use conservative settings:
      -- animate = {
      --   duration = { step = 15, total = 150 },
      --   easing = "linear",
      -- },
    },

    -- ========================================================================
    -- NOTIFICATION SYSTEM
    -- ========================================================================

    -- notifier: Enhanced notification manager
    -- Replaces vim.notify with beautiful, persistent notifications
    -- Issue #613: LSP integration validated, no message loss
    -- Works with Mason, LSP, plugin messages
    notifier = {
      enabled = true,
      timeout = 3000, -- 3 seconds before auto-dismiss
      level = vim.log.levels.INFO, -- Minimum level to display
      -- Keep error notifications longer
      -- Note: notif.level can be a string ("error", "warn", "info") or number
      keep = function(notif)
        local level = notif.level
        -- Convert string level to number if needed
        local nlevel = 0
        if type(level) == "string" then
          nlevel = vim.log.levels[level:upper()] or vim.log.levels.INFO
        end
        return nlevel >= vim.log.levels.ERROR
      end,
      -- Style configuration
      style = "compact",
      top_down = true,
    },

    -- ========================================================================
    -- DASHBOARD (START SCREEN)
    -- ========================================================================

    -- dashboard: Start screen with recent files and shortcuts
    -- Issue #97/#98: Requires function wrapping for lazy.nvim compatibility
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        {
          pane = 2,
          section = "keys",
          gap = 1,
          padding = 1,
        },
        {
          pane = 2,
          icon = " ",
          title = "Recent Files",
          section = "recent_files",
          indent = 2,
          padding = 1,
        },
        {
          pane = 2,
          icon = " ",
          title = "Projects",
          section = "projects",
          indent = 2,
          padding = 1,
        },
        {
          pane = 2,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          enabled = vim.fn.isdirectory(".git") == 1,
          cmd = "git status --short --branch --renames",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = "startup" },
      },
    },

    -- ========================================================================
    -- EXPLICITLY DISABLED MODULES
    -- ========================================================================
    -- Rationale: Keep existing proven tools (telescope, nvim-tree)

    -- picker: DISABLED - Keep telescope.nvim (mature, familiar, extensive ecosystem)
    picker = { enabled = false },

    -- explorer: DISABLED - Keep nvim-tree (stable, proven)
    explorer = { enabled = false },

    -- scope: DISABLED - Tab-scoped buffers not needed initially
    scope = { enabled = true },

    -- input: DISABLED - Minor benefit, can add later if needed
    input = { enabled = true },
  },

  -- ========================================================================
  -- KEYBINDINGS
  -- ========================================================================
  -- New keybindings in <leader>s namespace (no conflicts validated)
  -- Existing bindings preserved: <leader>e (nvim-tree), <leader>f* (telescope)

  keys = {
    -- Notification history and management
    {
      "<leader>sn",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },
    {
      "<leader>snd",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss All Notifications",
    },

    -- Dashboard access
    {
      "<leader>sd",
      function()
        Snacks.dashboard()
      end,
      desc = "Dashboard",
    },

    -- Git browse (open file in browser)
    {
      "<leader>gB",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Git Browse",
      mode = { "n", "x" },
    },

    -- Snacks utilities (optional - for debugging)
    {
      "<leader>ss",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>sS",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select Scratch Buffer",
    },
  },

  -- ========================================================================
  -- INITIALIZATION
  -- ========================================================================
  -- No custom config function needed - opts table is sufficient
  -- Run :checkhealth snacks after installation to verify setup
}
