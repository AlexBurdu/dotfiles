-- Tree-sitter is a parser generator tool that produces parsers for programming
-- languages.
-- In other words, it allows Neovim to understand the structure of code, allowing 
-- for better syntax highlighting, code folding, and other features.
-- https://github.com/nvim-treesitter/nvim-treesitter
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      -- A list of parser names, or "all"
      ensure_installed = "all",
      ignore_install = { "systemverilog" },
      --{
      --  "bash",
      --  "c",
      --  "cmake",
      --  "cpp",
      --  "css",
      --  "csv",
      --  "diff",
      --  "dockerfile",
      --  "java",
      --  "kotlin",
      --  "lua",
      --  "markdown",
      --  "markdown_inline",
      --  "proto",
      --  "python",
      --  "starlark",
      --  "vimdoc",
      --  "yaml"
      --},

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,

      -- Automatically install missing parsers when entering buffer
      -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
      auto_install = true,

      indent = {
        enable = true
      },

      highlight = {
        -- `false` will disable the whole extension
        enable = true,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = { "markdown" },
      },
    })
  end
}
