return {
  "mhinz/vim-signify",
  config = function()
    vim.keymap.set('n', '<Leader>vd', ':SignifyHunkDiff<CR>', { desc = 'Show hunk diff' })
  end
}
