-- Tree-sitter is a parser generator tool that produces parsers for programming
-- languages.
-- In other words, it allows Neovim to understand the structure of code, allowing
-- for better syntax highlighting, code folding, and other features.
-- https://github.com/nvim-treesitter/nvim-treesitter
return {
  "nvim-treesitter/nvim-treesitter",
  commit = "4916d6592ede8c07973490d9322f187e07dfefac",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = "all",
      ignore_install = { "systemverilog" },
      auto_install = true,
    })
  end
}
