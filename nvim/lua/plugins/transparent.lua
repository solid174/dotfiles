return {
  {
    "xiyaowong/transparent.nvim",
    config = function()
      require("transparent").setup({
        enable = true, -- <--- важно
        extra_groups = {
          "NormalFloat", -- чтобы popups тоже были прозрачными
          "NvimTreeNormal",
          "NeoTreeNormal",
          "FloatBorder",
          "StatusLine",
        },
      })
      require("transparent").clear_prefix("BufferLine") -- если используешь bufferline
    end,
  },
}
