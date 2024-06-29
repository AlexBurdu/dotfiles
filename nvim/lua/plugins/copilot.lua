-- https://github.com/github/copilot.vim
-- See :help copilot
-- When updating here, update ideavim/copilot.vim as well
return {
  "github/copilot.vim",

  config = function()
    vim.keymap.set('i', '<M-=>', '<Plug>(copilot-suggest)')
    vim.keymap.set('i', '<M-->', '<Plug>(copilot-dismiss)')
    vim.keymap.set('i', '<M-.>', '<Plug>(copilot-next)')
    vim.keymap.set('i', '<M-,>', '<Plug>(copilot-previous)')
    vim.keymap.set('i', '<M-/>', '<Plug>(copilot-accept-word)')
    vim.keymap.set('i', '<M-\\>', '<Plug>(copilot-accept-line)')
  end
}
