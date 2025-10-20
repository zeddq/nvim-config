-- UI Enhancement Plugins
-- Optional but recommended for better experience

return {
  -- File explorer: Moved to neo-tree.lua (unified git/jj support)
  -- See lua/plugins/neo-tree.lua for configuration

  config = function()
    require("nvim-tree").setup({
      view = {
        width = 30,
      },
      filters = {
        dotfiles = false,
      },
    })
    vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
  end,

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          component_separators = "|",
          section_separators = "",
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          -- Use fzf for better sorting
          file_sorter = require("telescope.sorters").get_fzf_sorter,
          generic_sorter = require("telescope.sorters").get_fzf_sorter,
        },
      })

      -- Load fzf extension
      telescope.load_extension("fzf")

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
      vim.keymap.set("n", "<leader>fr", builtin.registers, { desc = "Registers" })
    end,
  },

  -- Git integration (VCS-aware: disabled in jj repos)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local vcs = require("utils.vcs")

      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          interval = 1000,
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false,
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,

        -- CRITICAL: Conditional attachment based on VCS type
        on_attach = function(bufnr)
          -- Check VCS type for this buffer's directory
          local buf_path = vim.api.nvim_buf_get_name(bufnr)
          local vcs_type = vcs.detect_vcs_type(buf_path)

          -- Only attach gitsigns in git repos or non-repos
          -- NEVER attach in jj repos (jj has .git but should use jj commands)
          if vcs_type == "jj" then
            return false -- Don't attach to this buffer
          end

          -- Git repo or non-repo: proceed with attachment
          local gs = package.loaded.gitsigns

          -- Keymaps for git operations
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Next git hunk" })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Previous git hunk" })

          -- Actions
          map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
          map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
          map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Stage hunk (visual)" })
          map("v", "<leader>hr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Reset hunk (visual)" })
          map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
          map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
          map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
          map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
          end, { desc = "Blame line" })
          map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
          map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
          map("n", "<leader>hD", function()
            gs.diffthis("~")
          end, { desc = "Diff this ~" })
          map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted" })

          -- Text object
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })

          return true -- Attachment successful
        end,
      })

      -- Refresh gitsigns when VCS cache is cleared
      vim.api.nvim_create_autocmd("User", {
        pattern = "VCSCacheCleared",
        callback = function()
          -- Force gitsigns to re-evaluate all buffers
          vim.schedule(function()
            require("gitsigns").refresh()
          end)
        end,
      })
    end,
  },

  -- Color scheme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      styles = { comments = { italic = false }, keywords = { italic = false } },
      on_highlights = function(hl, c)
        hl.Visual = { bg = c.blue5, fg = c.bg }
        hl.Search = { bg = c.yellow, fg = c.bg, bold = true }
        hl.IncSearch = { bg = c.orange, fg = c.bg, bold = true }
        hl.CursorLine = { bg = c.bg_highlight }
        hl.CursorLineNr = { fg = c.yellow, bold = true }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Register viewer: shows a floating window when you press '"', '@', or <C-r>
  {
    "Tversteeg/registers.nvim",
    opts = {
      window = { max_width = 100 },
    },
    config = function(_, opts)
      local r = require("registers")
      -- Apply user options
      r.setup(opts)
      -- Workaround: ensure popup has a minimum width to avoid errors when all registers are empty
      if type(r._longest_register_length) == "function" then
        local orig = r._longest_register_length
        r._longest_register_length = function()
          local w = orig()
          if w == nil or w < 10 then
            return 10
          end
          return w
        end
      end
    end,
  },

  -- Which-key: discoverable keymaps
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}
