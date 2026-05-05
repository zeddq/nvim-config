-- Minuet AI: as-you-type inline (ghost text) completion via Codestral FIM.
-- Uses Mistral's dedicated Codestral fill-in-the-middle endpoint.
-- Requires the CODESTRAL_API_KEY environment variable to be exported in the
-- shell that launches nvim (get a key from https://console.mistral.ai).
--
-- The virtualtext frontend coexists with nvim-cmp: cmp drives the popup menu,
-- minuet draws ghost text inline.

return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "InsertEnter",
    config = function()
      require("minuet").setup({
        provider = "codestral",

        -- Surface warnings/errors (e.g. missing key, timeouts) but stay quiet
        -- in normal use. Flip to "debug" to inspect every request/response.
        notify = "warn",

        -- One completion per trigger keeps latency and token spend down while
        -- evaluating. Bump to 2-3 to cycle alternatives with <A-]> / <A-[>.
        n_completions = 1,

        -- Chars of surrounding code (prefix + suffix) sent as FIM context.
        context_window = 16000,

        -- Auto-trigger pacing (ms): throttle = min gap between requests,
        -- debounce = wait for typing to settle before firing.
        throttle = 1000,
        debounce = 400,

        provider_options = {
          codestral = {
            model = "codestral-latest",
            end_point = "https://codestral.mistral.ai/v1/fim/completions",
            api_key = "CODESTRAL_API_KEY",
            stream = true,
            optional = {
              -- Cap generation so completions stay snappy and don't time out;
              -- stop at a blank line, the usual end of a useful completion.
              max_tokens = 256,
              stop = { "\n\n" },
            },
          },
        },

        virtualtext = {
          -- Ghost text in every filetype. Restrict to a list to narrow scope,
          -- e.g. { "lua", "python", "rust" }.
          auto_trigger_ft = { "*" },
          keymap = {
            accept = "<A-Tab>", -- accept the whole suggestion
            accept_line = "<A-a>", -- accept one line
            accept_n_lines = "<A-z>", -- accept N lines (prompts for count)
            next = "<A-]>", -- cycle to next completion
            prev = "<A-[>", -- cycle to previous completion
            dismiss = "<A-e>", -- dismiss current ghost text
          },
        },
      })

      -- Session request counter for visibility into API usage (handy on the
      -- free tier). Reset per nvim session.
      local request_count = 0
      vim.api.nvim_create_autocmd("User", {
        pattern = "MinuetRequestStarted",
        callback = function()
          request_count = request_count + 1
        end,
      })

      -- QoL commands ---------------------------------------------------------

      vim.api.nvim_create_user_command("MinuetStatus", function()
        local visible = require("minuet.virtualtext").action.is_visible()
        local cfg = require("minuet").config
        vim.notify(
          ("Minuet | provider: %s | ghost text visible: %s | requests: %d")
            :format(cfg.provider, tostring(visible), request_count),
          vim.log.levels.INFO
        )
      end, { desc = "Minuet: show session status" })

      vim.api.nvim_create_user_command("MinuetRequestCount", function()
        vim.notify(("Minuet requests this session: %d"):format(request_count))
      end, { desc = "Minuet: show session request count" })

      -- QoL keymaps (<leader>a* = AI) ---------------------------------------

      vim.keymap.set(
        "n",
        "<leader>at",
        "<cmd>Minuet virtualtext toggle<cr>",
        { desc = "Minuet: toggle inline completion" }
      )
      vim.keymap.set(
        "n",
        "<leader>am",
        "<cmd>Minuet change_model<cr>",
        { desc = "Minuet: change model" }
      )
      vim.keymap.set(
        "n",
        "<leader>as",
        "<cmd>MinuetStatus<cr>",
        { desc = "Minuet: status" }
      )
      vim.keymap.set(
        "n",
        "<leader>ac",
        "<cmd>MinuetRequestCount<cr>",
        { desc = "Minuet: request count" }
      )
    end,
  },
}
