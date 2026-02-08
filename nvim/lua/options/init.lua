vim.cmd('source ~/.config/nvim/lua/options/options.vim')

-- Treat VS Code JSON files as JSONC (allows // comments)
vim.filetype.add({
  pattern = {
    [".*/vscode/.*%.json"] = "jsonc",
    ["%.vscode/.*%.json"] = "jsonc",
  },
})

