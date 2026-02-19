-- Insert review comment markers [>> ]
-- Normal mode: inserts [>> ] with cursor after ">> "
-- Visual mode: wraps selection as [selected text >> ] with cursor after ">> "

vim.keymap.set('n', '<Leader><Leader>c', function()
  vim.api.nvim_put({'[>> ]'}, 'c', false, false)
  -- Position cursor between ">> " and "]"
  local col = vim.fn.col('.')
  vim.api.nvim_win_set_cursor(0, {vim.fn.line('.'), col + 3})
  vim.cmd('startinsert')
end, { desc = 'Insert review comment' })

vim.keymap.set('v', '<Leader><Leader>c', function()
  -- Yank selection to register z
  vim.cmd('normal! "zy')
  local text = vim.fn.getreg('z')
  -- Delete the selection
  vim.cmd('normal! gv"_d')
  -- Insert wrapped text
  vim.api.nvim_put({'[' .. text .. ' >> ]'}, 'c', false, false)
  -- Position cursor between ">> " and "]"
  local col = vim.fn.col('.')
  vim.api.nvim_win_set_cursor(0, {vim.fn.line('.'), col + #text + 5})
  vim.cmd('startinsert')
end, { desc = 'Wrap selection in review comment' })
