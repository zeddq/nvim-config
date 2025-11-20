-- Neo-tree File Exglorer with Jujutsu Support
-- REPLACES nvim-tree entirely - works for git, jj, and non-VCS directories
--
-- Commands: :Neotree toggle, :Neotree filesystem, :Neotree git_status, :Neotree jj
-- Sources automatically switch based on repository type

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "Cretezy/neo-tree-jj.nvim", -- Jujutsu integration
    },
    cmd = "Neotree", -- Lazy-load on command
    keys = {
      -- Main toggle (configured in vcs-keymaps.lua, but also here for lazy loading)
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true })
        end,
        desc = "Toggle Neo-tree",
      },
      -- Quick access to specific sources
      {
        "<leader>eg",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true })
        end,
        desc = "Neo-tree: Git status",
      },
      {
        "<leader>ej",
        function()
          require("neo-tree.command").execute({ source = "jj", toggle = true })
        end,
        desc = "Neo-tree: Jujutsu status",
      },
    },
    opts = function(_, opts)
      -- Initialize opts if not provided
      opts = opts or {}

      -- Register jj source for neo-tree-jj.nvim
      opts.sources = opts.sources or { "filesystem", "buffers", "git_status" }
      table.insert(opts.sources, "jj")

      -- General settings
      opts.close_if_last_window = true
      opts.popup_border_style = "rounded"
      opts.enable_git_status = true
      opts.enable_diagnostics = true
      opts.sort_case_insensitive = false

      -- Source selector (tabs at top)
      opts.source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          { source = "filesystem", display_name = " 󰉓 Files " },
          { source = "buffers", display_name = " 󰈚 Buffers " },
          { source = "git_status", display_name = " 󰊢 Git " },
          { source = "jj", display_name = " 󰊢 JJ " },
        },
        content_layout = "center",
        tabs_layout = "equal",
      }

      -- Default component configs
      opts.default_component_configs = {
        container = {
          enable_character_fade = true,
        },
        indent = {
          indent_size = 2,
          padding = 1,
          with_markers = true,
          indent_marker = "│",
          last_indent_marker = "└",
          highlight = "NeoTreeIndentMarker",
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "󰜌",
          default = "*",
          highlight = "NeoTreeFileIcon",
        },
        modified = {
          symbol = "[+]",
          highlight = "NeoTreeModified",
        },
        name = {
          trailing_slash = false,
          use_git_status_colors = true,
          highlight = "NeoTreeFileName",
        },
        git_status = {
          symbols = {
            -- Change type
            added = "✚", -- or "A"
            modified = "", -- or "M"
            deleted = "✖", -- or "D"
            renamed = "󰁕", -- or "R"
            -- Status type
            untracked = "",
            ignored = "",
            unstaged = "󰄱",
            staged = "",
            conflict = "",
          },
        },
      }

      -- Window settings
      opts.window = {
        position = "left",
        width = 30,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
        mappings = {
          ["<space>"] = "none", -- Disable space (conflicts with leader)

          -- Navigation
          ["<CR>"] = "open",
          ["l"] = "open",
          ["h"] = "close_node",
          ["<BS>"] = "navigate_up",
          ["z"] = "close_all_nodes",
          ["Z"] = "expand_all_nodes",

          -- Splits
          ["s"] = "open_split",
          ["v"] = "open_vsplit",
          ["t"] = "open_tabnew",

          -- File operations
          ["a"] = {
            "add",
            config = {
              show_path = "relative",
            },
          },
          ["d"] = "delete",
          ["r"] = "rename",
          ["c"] = "copy",
          ["x"] = "cut",
          ["p"] = "paste",
          ["y"] = "copy_to_clipboard",

          -- Refresh & other
          ["R"] = "refresh",
          ["?"] = "show_help",
          ["q"] = "close_window",
          ["<Esc>"] = "cancel",

          -- Toggle hidden files
          ["H"] = "toggle_hidden",
          ["."] = "set_root",

          -- Search
          ["/"] = "fuzzy_finder",
          ["D"] = "fuzzy_finder_directory",
          ["#"] = "fuzzy_sorter",
          ["f"] = "filter_on_submit",
          ["<C-x>"] = "clear_filter",

          -- Git operations (available in git_status and filesystem sources)
          ["gu"] = "git_unstage_file",
          ["ga"] = "git_add_file",
          ["gr"] = "git_revert_file",
          ["gc"] = "git_commit",
          ["gp"] = "git_push",
          ["gg"] = "git_commit_and_push",
        },
      }

      -- Filesystem source configuration
      opts.filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {
            ".DS_Store",
            "thumbs.db",
            ".git",
          },
          never_show = {},
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        group_empty_dirs = false,
        hijack_netrw_behavior = "open_default",
        use_libuv_file_watcher = true,
        -- Auto-change neovim's cwd when setting neo-tree root
        cwd_target = {
          sidebar = "window", -- neo-tree sidebar follows its own cwd
          current = "global", -- change neovim's global cwd when setting root
        },
        window = {
          mappings = {
            ["<BS>"] = "navigate_up",
            ["."] = "set_root",
            ["[g"] = "prev_git_modified",
            ["]g"] = "next_git_modified",
          },
        },
      }

      -- Buffers source configuration
      opts.buffers = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        group_empty_dirs = true,
        show_unloaded = true,
        window = {
          mappings = {
            ["bd"] = "buffer_delete",
            ["<BS>"] = "navigate_up",
            ["."] = "set_root",
          },
        },
      }

      -- Git status source configuration
      opts.git_status = {
        window = {
          position = "float",
          mappings = {
            ["gu"] = "git_unstage_file",
            ["ga"] = "git_add_file",
            ["gr"] = "git_revert_file",
            ["gc"] = "git_commit",
            ["gp"] = "git_push",
            ["gg"] = "git_commit_and_push",
          },
        },
      }

      return opts
    end,
    config = function(_, opts)
      -- Load VCS utilities for conditional behavior
      local vcs = require("utils.vcs")

      -- Apply configuration
      require("neo-tree").setup(opts)

      -- Auto-switch source based on VCS type when opening neo-tree
      vim.api.nvim_create_autocmd("User", {
        pattern = "Neo-treeBeforeOpenFileTree",
        callback = function()
          local vcs_type = vcs.detect_vcs_type()

          -- Auto-select appropriate source tab
          if vcs_type == "jj" then
            -- In jj repo, prefer jj source
            vim.defer_fn(function()
              require("neo-tree.sources.manager").show("jj")
            end, 100)
          elseif vcs_type == "git" then
            -- In git repo, prefer git_status source
            -- (but filesystem is default, which is fine)
          end
        end,
      })

      -- Integration with gitsigns: refresh when gitsigns updates
      vim.api.nvim_create_autocmd("User", {
        pattern = "GitSignsUpdate",
        callback = function()
          require("neo-tree.sources.manager").refresh("git_status")
        end,
      })

      -- Integration with VCS cache: refresh when cache is cleared
      vim.api.nvim_create_autocmd("User", {
        pattern = "VCSCacheCleared",
        callback = function()
          require("neo-tree.sources.manager").refresh("filesystem")
          require("neo-tree.sources.manager").refresh("git_status")
          require("neo-tree.sources.manager").refresh("jj")
        end,
      })
    end,
  },
}
