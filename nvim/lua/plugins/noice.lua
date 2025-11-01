return {
  "folke/noice.nvim",
  opts = {
    cmdline = {
      view = "cmdline", -- ВНИЗУ экрана
    },
    messages = {
      view = "mini", -- упрощённый вывод сообщений
    },
    popupmenu = {
      enabled = true, -- нужно для cmp-cmdline
    },
    presets = {
      bottom_search = true, -- перемещает / и ? вниз
      command_palette = false,
      long_message_to_split = true,
      lsp_doc_border = true,
    },
  },
}
