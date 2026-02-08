return {
  'numToStr/Comment.nvim',
  config = function()
    require('Comment').setup()
    -- C-/ to toggle comment (works in normal and visual mode)
    -- Note: C-/ sends C-_ in most terminals
    vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment' })
    vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment' })
    vim.keymap.set('v', '<C-/>', 'gc', { remap = true, desc = 'Toggle comment' })
    vim.keymap.set('v', '<C-_>', 'gc', { remap = true, desc = 'Toggle comment' })
  end
}
