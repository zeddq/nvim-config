-- Autocompletion Configuration
-- nvim-cmp with LSP integration

return {
  {
    "hrsh7th/nvim-cmp",
    priority = 999,
    lazy = false,
    dependencies = {
      -- Completion sources
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",

      -- Snippet engine (required by nvim-cmp)
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",

      -- Optional: friendly snippets
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load friendly snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Load custom snippets from ~/.config/nvim/snippets/
      require("luasnip.loaders.from_lua").lazy_load({ paths = "~/.config/nvim/snippets" })

      ---@type cmp.ConfigSchema
      local cfg = {
        snippet = {
          ---@param args cmp.SnippetExpansionParams
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-S-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),

          -- Tab completion
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        -- Flat list with an explicit group_index on every source, rather than
        -- cmp.config.sources(g1, g2, ...). That helper force-assigns
        -- group_index = <argument position>, which would silently overwrite
        -- lazydev's 0. The numbers below reproduce the previous grouping
        -- exactly; sources that had no explicit index take the id of the group
        -- they already sat in.
        ---@type cmp.SourceConfig[]
        sources = {
          { name = "nvim_lsp", group_index = 1 },
          -- Group 0 supersedes lua_ls instead of ranking beside it, so `vim.*`
          -- completions come from lazydev alone with no duplicates.
          { name = "lazydev", group_index = 0 },
          { name = "luasnip", group_index = 2 },
          { name = "path", group_index = 3 },
          { name = "buffer", keyword_length = 3, group_index = 4 },
        },
        formatting = {
          ---@param entry cmp.Entry
          ---@param vim_item vim.CompletedItem
          ---@return vim.CompletedItem
          format = function(entry, vim_item)
            -- Kind icons
            local icons = {
              Text = "",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "",
              Field = "󰇽",
              Variable = "󰂡",
              Class = "󰠱",
              Interface = "",
              Module = "",
              Property = "󰜢",
              Unit = "",
              Value = "󰎠",
              Enum = "",
              Keyword = "󰌋",
              Snippet = "",
              Color = "󰏘",
              File = "󰈙",
              Reference = "",
              Folder = "󰉋",
              EnumMember = "",
              Constant = "󰏿",
              Struct = "",
              Event = "",
              Operator = "󰆕",
              TypeParameter = "󰅲",
            }

            vim_item.kind = string.format("%s %s", icons[vim_item.kind], vim_item.kind)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]

            return vim_item
          end,
        },
      }
      cmp.setup(cfg)

      -- Command-line completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
          { name = "nvim_lsp" },
          { name = "buffer" },
        }),
        -- upstream cmp.MatchingConfig marks every field required; runtime defaults exist
        ---@diagnostic disable-next-line: missing-fields
        matching = { disallow_symbol_nonprefix_matching = false },
      })

      -- Search completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },
}
