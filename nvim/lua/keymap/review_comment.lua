-- Insert review comment markers [>> ]
-- Normal mode: inserts [>> ] with cursor after ">> "
-- Visual mode: wraps selection as [selected text >> ]
--   with cursor after ">> "

vim.keymap.set('n', '<Leader><Leader>c', function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  vim.api.nvim_set_current_line(before .. '[>> ]' .. after)
  -- Cursor on the space before ]
  vim.api.nvim_win_set_cursor(0, {row, col + 4})
  vim.cmd('startinsert')
end, { desc = 'Insert review comment' })

vim.keymap.set('v', '<Leader><Leader>c', function()
  -- Yank selection to register z
  vim.cmd('normal! "zy')
  local text = vim.fn.getreg('z')
  -- Delete the selection
  vim.cmd('normal! gv"_d')
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  local insert = '[' .. text .. ' >> ]'
  vim.api.nvim_set_current_line(before .. insert .. after)
  -- Cursor on the space before ]
  vim.api.nvim_win_set_cursor(0, {row, col + #insert - 1})
  vim.cmd('startinsert')
end, { desc = 'Wrap selection in review comment' })
