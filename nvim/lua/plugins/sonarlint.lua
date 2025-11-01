return {
  "https://gitlab.com/schrieveslaach/sonarlint.nvim.git",
  dependencies = { "mfussenegger/nvim-jdtls" }, -- нужен для Java-зависимостей
  config = function()
    local mason_share = vim.fn.stdpath("data") .. "/mason/share/sonarlint-analyzers"
    local mason_pkg = vim.fn.stdpath("data") .. "/mason/packages/sonarlint-language-server/extension"

    require("sonarlint").setup({
      server = {
        cmd = {
          "sonarlint-language-server",
          "-stdio",
          "-analyzers",
          mason_share .. "/sonarcfamily.jar",
          mason_share .. "/sonarjs.jar",
          mason_share .. "/sonarpython.jar",
          mason_share .. "/sonarlintomnisharp.jar",
        },
        init_options = {
          omnisharpDirectory = mason_pkg .. "/omnisharp",
          csharpOssPath = mason_share .. "/sonarcsharp.jar",
          csharpEnterprisePath = mason_share .. "/csharpenterprise.jar",
        },
      },
      filetypes = {
        -- Frontend first
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "html",
        "css",
        -- Backend
        "cs",
        "cpp",
        "python",
        -- Infrastructure
        "dockerfile",
      },
    })
  end,
}
