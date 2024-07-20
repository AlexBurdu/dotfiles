-- https://github.com/github/copilot.vim
-- See :help copilot
-- When updating here, update ideavim/copilot.vim as well
return {
  "github/copilot.vim",

  config = function()
    vim.keymap.set('i', '<C-u>', '<Plug>(copilot-suggest)')
    vim.keymap.set('i', '<C-d>', '<Plug>(copilot-dismiss)')
    vim.keymap.set('i', '<C-j>', '<Plug>(copilot-next)')
    vim.keymap.set('i', '<C-k>', '<Plug>(copilot-previous)')
    vim.keymap.set('i', '<C-l>', '<Plug>(copilot-accept-word)')
    vim.keymap.set('i', '<C-h>', '<Plug>(copilot-accept-line)')
  end
}
