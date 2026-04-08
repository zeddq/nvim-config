return {
  "javiorfo/nvim-soil",
  lazy = true,
  ft = "plantuml",
  config = function()
    -- Find PlantUML jar: env var first, then common install paths
    local function find_puml_jar()
      if vim.env.PLANTUML_JAR then
        return vim.env.PLANTUML_JAR
      end
      local paths = {
        "/opt/homebrew/opt/plantuml/libexec/plantuml.jar",
        "/usr/local/opt/plantuml/libexec/plantuml.jar",
        "/usr/share/java/plantuml.jar",
      }
      for _, p in ipairs(paths) do
        if vim.uv.fs_stat(p) then
          return p
        end
      end
      return paths[1] -- fallback to homebrew path
    end

    local puml_jar = find_puml_jar()
    if not vim.uv.fs_stat(puml_jar) then
      vim.notify("PlantUML jar not found. Set PLANTUML_JAR or: brew install plantuml", vim.log.levels.WARN)
    end

    require("soil").setup({
      puml_jar = puml_jar,
      actions = {
        redraw = true,
      },
      image = {
        darkmode = true,
        format = "png",
        execute_to_open = function(img)
          return "open -a Preview " .. img
        end,
      },
    })
  end,

  keys = {
    { "<leader>pu", "<cmd>Soil<cr>", ft = "plantuml", desc = "Render PlantUML" },
  },

  dependencies = { "javiorfo/nvim-nyctophilia" },
}
