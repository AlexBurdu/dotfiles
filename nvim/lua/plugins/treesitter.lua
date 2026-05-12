-- Tree-sitter is a parser generator tool that produces parsers for programming
-- languages.
-- In other words, it allows Neovim to understand the structure of code, allowing
-- for better syntax highlighting, code folding, and other features.
-- https://github.com/nvim-treesitter/nvim-treesitter
return {
  "nvim-treesitter/nvim-treesitter",
  commit = "4916d6592ede8c07973490d9322f187e07dfefac",
  build = function()
    -- Parsers compile via the tree-sitter CLI. Homebrew split this out: the
    -- `tree-sitter` formula now ships only libtree-sitter, and the CLI lives
    -- in `tree-sitter-cli`. Without it, :TSUpdate silently no-ops and bundled
    -- parsers drift out of sync with the plugin's queries (e.g. lua's
    -- `(binary_expression operator: _ @operator)` requires a recent parser).
    if vim.fn.executable("tree-sitter") == 0 then
      if vim.fn.executable("brew") == 1 then
        vim.notify("Installing tree-sitter-cli via Homebrew", vim.log.levels.INFO)
        vim.fn.system({ "brew", "install", "tree-sitter-cli" })
      else
        vim.notify(
          "tree-sitter CLI missing; install it manually so :TSUpdate can rebuild parsers",
          vim.log.levels.WARN
        )
        return
      end
    end
    vim.cmd("TSUpdate")
  end,
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = "all",
      ignore_install = { "systemverilog" },
      auto_install = true,
    })
  end
}
