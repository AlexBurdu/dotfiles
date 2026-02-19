return {
  "mhinz/vim-signify",
  config = function()
    vim.keymap.set('n', '<Leader>vd', ':SignifyHunkDiff<CR>', { desc = 'Show hunk diff' })
    vim.keymap.set('n', '<Leader>vn', '<plug>(signify-next-hunk)', { desc = 'Next change hunk' })
    vim.keymap.set('n', '<Leader>vN', '<plug>(signify-prev-hunk)', { desc = 'Previous change hunk' })
  end
}
