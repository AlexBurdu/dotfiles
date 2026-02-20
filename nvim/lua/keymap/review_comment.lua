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
  -- Yank selection to register z (exits visual mode, sets '< and '>)
  vim.cmd('normal! "zy')
  local text = vim.fn.getreg('z')
  -- Get selection range (marks are valid now after exiting visual mode)
  local _, sr, sc, _ = unpack(vim.fn.getpos("'<"))
  local _, er, ec, _ = unpack(vim.fn.getpos("'>"))
  -- Clamp ec for end-of-line selections (v:maxcol)
  local end_line = vim.api.nvim_buf_get_lines(0, er - 1, er, true)[1]
  ec = math.min(ec, #end_line)
  -- Remove trailing newline from linewise yank
  text = text:gsub('\n$', '')
  -- Split into lines for multi-line replacement
  local lines = vim.split(text, '\n', { plain = true })
  -- Wrap: first line gets "[", last line gets " >> ]"
  lines[1] = '[' .. lines[1]
  lines[#lines] = lines[#lines] .. ' >> ]'
  -- Replace the visual selection with wrapped text
  vim.api.nvim_buf_set_text(0, sr - 1, sc - 1, er - 1, ec, lines)
  -- Place cursor on "]" so startinsert types before it
  local end_row = sr - 1 + #lines - 1
  local end_col
  if #lines == 1 then
    end_col = (sc - 1) + #lines[1] - 1
  else
    end_col = #lines[#lines] - 1
  end
  vim.api.nvim_win_set_cursor(0, {end_row + 1, end_col})
  vim.cmd('startinsert')
end, { desc = 'Wrap selection in review comment' })
