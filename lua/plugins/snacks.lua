return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = {
      enabled = true,
      size = 1.5 * 1024 * 1024,
      setup = function(ctx)
        vim.b.minianimate_disable = true
        vim.schedule(function()
          vim.bo[ctx.buf].syntax = ctx.ft
        end)
      end,
    },
    quickfile = { enabled = true },
    statuscolumn = {
      enabled = true,
      left = { "mark", "sign" },
      right = { "fold", "git" },
      git = { patterns = { "GitSign", "MiniDiffSign" } },
    },
    indent = { enabled = true, char = "│", blank = " ", only_scope = false, only_current = false },
    words = { enabled = true, debounce = 200, modes = { "n", "i", "c" } },
    scroll = { enabled = false },
    notifier = { enabled = true, timeout = 3000, level = vim.log.levels.INFO, style = "compact", top_down = true },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { pane = 2, section = "keys", gap = 1, padding = 1 },
        { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        {
          pane = 2,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          enabled = require("utils.vcs").detect_vcs_type() == "git",
          cmd = "git status --short --branch --renames",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = "startup" },
      },
    },
    terminal = { enabled = true, win = { style = "terminal" } },
    picker = {
      enabled = false,
      -- preview
      sources = {
        -- Reusable static-items picker: `Snacks.picker.my_tasks()`
        my_tasks = {
          title = "My Tasks",
          layout = { preset = "select" },
          finder = function()
            local tasks = {
              { name = "deploy", env = "prod", port = 8080, desc = "Deploy service" },
              { name = "migrate", env = "staging", port = 5432, desc = "Run DB migrations" },
              { name = "seed", env = "dev", port = 5432, desc = "Seed test data" },
            }
            local items = {}
            for i, task in ipairs(tasks) do
              -- `text` is what the fuzzy matcher searches; display is controlled by `format`
              items[#items + 1] = { idx = i, text = task.name .. " " .. task.env, task = task }
            end
            return items
          end,
          format = function(item)
            local task = item.task
            local a = Snacks.picker.util.align
            return {
              { a(task.name, 12), "SnacksPickerLabel" },
              { a(task.env, 10), "SnacksPickerSpecial" },
              { a(tostring(task.port), 6, { align = "right" }), "Number" },
              { "  " },
              { task.desc, "SnacksPickerComment" },
            }
          end,
          confirm = function(picker, item)
            picker:close()
            vim.notify("Running " .. item.task.name .. " on " .. item.task.env)
          end,
        },
        -- Toggle-style list over the Snacks.toggle registry: `Snacks.picker.config_toggles()`
        -- <CR> flips the switch and keeps the picker open for the next item.
        config_toggles = {
          title = "Config Toggles",
          layout = { preset = "select" },
          matcher = { sort_empty = false },
          finder = function()
            local ids = vim.tbl_keys(Snacks.toggle.toggles)
            vim.tbl_count(Snacks.toggle.toggles)
            table.sort(ids)
            local items = {}
            for i, id in ipairs(ids) do
              local toggle = Snacks.toggle.toggles[id]
              items[#items + 1] = { idx = i, text = toggle.opts.name or id, toggle = toggle }
            end
            return items
          end,
          format = function(item)
            local on = item.toggle:get()
            return {
              { on and "● " or "○ ", on and "DiagnosticOk" or "SnacksPickerComment" },
              { Snacks.picker.util.align(item.text, 32) },
              { on and "on" or "off", on and "DiagnosticOk" or "SnacksPickerComment" },
            }
          end,
          confirm = function(picker, item)
            if item then
              item.toggle:toggle()
              picker:find({ refresh = true }) -- Rerun finder so the ●/○ state re-renders
            end
          end,
        },
      },
    },
    explorer = { enabled = false },
    scope = { enabled = true },
    input = { enabled = true },
  },
  keys = {
    {
      -- "<c-/>",
      "<C-/>",
      function()
        Snacks.terminal()
      end,
      desc = "Toggle Terminal",
      mode = { "n", "t" },
    },
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
    {
      "<leader>sd",
      function()
        Snacks.dashboard()
      end,
      desc = "Dashboard",
    },
    {
      "<leader>gO",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Git Browse",
      mode = { "n", "x" },
    },
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
    {
      "<leader>sbda",
      function()
        Snacks.bufdelete.all()
      end,
      desc = "Delete All Buffers",
    },
    {
      "<leader>sbdo",
      function()
        Snacks.bufdelete.other()
      end,
      desc = "Delete All-But-Current Buffers",
    },
    {
      "<leader>stL",
      function()
        Snacks.picker.config_toggles()
      end,
      desc = "Toggles",
    },
    {
      "<leader>sp",
      function()
        Snacks.picker.my_tasks()
      end,
      desc = "My Tasks Picker",
    },
  },
}
