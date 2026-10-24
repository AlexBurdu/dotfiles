-- Optional (`kotlin-lsp` in machine.sh): JetBrains kotlin-lsp, the
-- open-source Kotlin server from github.com/Kotlin/kotlin-lsp.
--
-- Mason's kotlin-lsp package links the server as intellij-server, the
-- command nvim-lspconfig's kotlin_lsp config already runs. The server
-- imports the Gradle or Maven build at the root it is given; the first
-- import of a large build takes minutes, and later ones reuse its index.
--
-- It fills the `kotlin` entry of lsp.lua's servers, which jvm.lua fills
-- too. lazy.nvim merges plugins/ in alphabetical order, so with `jvm` on
-- as well this entry wins and jvm.lua's Kotlin servers (and Space bJ)
-- stay off; its debugger and Android attach are unaffected.
return {
  "neovim/nvim-lspconfig",
  opts = {
    ensure_installed = { kotlin_lsp = true },
    servers = {
      kotlin = function(capabilities)
        vim.lsp.config("kotlin_lsp", {
          capabilities = capabilities,
          -- A settings file anywhere above wins over a nearer build
          -- file, so a file in a subproject imports the whole build.
          root_markers = {
            { "settings.gradle.kts", "settings.gradle" },
            { "pom.xml", "build.gradle.kts", "build.gradle" },
          },
        })
        vim.lsp.enable("kotlin_lsp")
      end,
    },
  },
}
