return {
  "javiorfo/nvim-soil",
  lazy = true,
  ft = "plantuml",
  config = function()
    require("soil").setup({
      puml_jar = "/opt/homebrew/opt/plantuml/libexec/plantuml.jar",
      actions = {
        redraw = true,
      },
      image = {
        darkmode = true, -- use dark mode for diagram
        format = "png", -- output format: png, svg, eps, etc.

        -- Command to view the image (examples):
        execute_to_open = function(img)
          -- macOS Preview
          return "open -a Preview " .. img

          -- or use a specific app like feh, sxiv, etc.
          -- return "feh " .. img
          -- return "sxiv " .. img
        end,
      },
    })
  end,

  keys = {
    { "<leader>pu", "<cmd>Soil<cr>", ft = "plantuml", desc = "Render PlantUML" },
  },

  dependencies = { "javiorfo/nvim-nyctophilia" },
}
