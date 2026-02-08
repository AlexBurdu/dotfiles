return {
  'nvim-pack/nvim-spectre',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('spectre').setup()
    -- Replace in path (like IntelliJ's ReplaceInPath)
    vim.keymap.set('n', '<Leader>fr', require('spectre').open, { desc = 'Replace in path' })
    vim.keymap.set('v', '<Leader>fr', require('spectre').open_visual, { desc = 'Replace selection in path' })
  end
}
