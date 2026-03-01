-- CriticMarkup review annotations
-- Keybindings under <Leader>c ("Critic" prefix):
--   cc  Comment     {>> comment <<}                  (n: insert, v: highlight+comment)
--   ch  Highlight   {== text ==}                     (n: char under cursor, v: wrap selection)
--   ci  Insert      {++ text ++}                     (n: insert at cursor)
--   cd  Delete      {-- text --}                     (n: char under cursor, v: wrap selection)
--   cs  Substitute  {~~ old ~> new ~~}               (n: char under cursor, v: wrap selection)

-- Helper: wrap char under cursor with prefix/suffix (normal mode)
local function wrap_char(prefix, suffix)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(col + 1, col + 1)
  if char == '' then return end
  local before = line:sub(1, col)
  local after = line:sub(col + 2)
  vim.api.nvim_set_current_line(before .. prefix .. char .. suffix .. after)
  vim.api.nvim_win_set_cursor(0, {row, col + #prefix})
end

-- Helper: wrap visual selection with prefix/suffix, position cursor
local function wrap_selection(prefix, suffix, cursor_from_end)
  vim.cmd('normal! "zy')
  local text = vim.fn.getreg('z')
  local _, sr, sc, _ = unpack(vim.fn.getpos("'<"))
  local _, er, ec, _ = unpack(vim.fn.getpos("'>"))
  local end_line = vim.api.nvim_buf_get_lines(0, er - 1, er, true)[1]
  ec = math.min(ec, #end_line)
  text = text:gsub('\n$', '')
  local lines = vim.split(text, '\n', { plain = true })
  lines[1] = prefix .. lines[1]
  lines[#lines] = lines[#lines] .. suffix
  vim.api.nvim_buf_set_text(0, sr - 1, sc - 1, er - 1, ec, lines)
  local end_row = sr - 1 + #lines - 1
  local end_col
  if #lines == 1 then
    end_col = (sc - 1) + #lines[1] - cursor_from_end
  else
    end_col = #lines[#lines] - cursor_from_end
  end
  vim.api.nvim_win_set_cursor(0, {end_row + 1, end_col})
  vim.cmd('startinsert')
end

-- Comment: {== char ==}{>> comment <<}
vim.keymap.set('n', '<Leader>cc', function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(col + 1, col + 1)
  if char == '' then return end
  local before = line:sub(1, col)
  local after = line:sub(col + 2)
  local marker = '{== ' .. char .. ' ==}{>>  <<}'
  vim.api.nvim_set_current_line(before .. marker .. after)
  -- Cursor on space before <<} so user types the comment
  vim.api.nvim_win_set_cursor(0, {row, col + #'{== ' + #char + #' ==}{>> '})
  vim.cmd('startinsert')
end, { desc = 'CriticMarkup: comment on char' })

vim.keymap.set('v', '<Leader>cc', function()
  wrap_selection('{== ', ' ==}{>>  <<}', 4)
end, { desc = 'CriticMarkup: highlight + comment' })

-- Highlight: {== text ==}
vim.keymap.set('n', '<Leader>ch', function()
  wrap_char('{== ', ' ==}')
end, { desc = 'CriticMarkup: highlight char' })

vim.keymap.set('v', '<Leader>ch', function()
  wrap_selection('{== ', ' ==}', 1)
end, { desc = 'CriticMarkup: highlight' })

-- Insert: {++ text ++}
vim.keymap.set('n', '<Leader>ci', function()
  wrap_char('{++ ', ' ++}')
end, { desc = 'CriticMarkup: mark char insertion' })

-- Delete: {-- text --}
vim.keymap.set('n', '<Leader>cd', function()
  wrap_char('{-- ', ' --}')
end, { desc = 'CriticMarkup: mark char deletion' })

vim.keymap.set('v', '<Leader>cd', function()
  wrap_selection('{-- ', ' --}', 1)
end, { desc = 'CriticMarkup: mark deletion' })

-- Substitute: {~~ old ~> new ~~}
vim.keymap.set('n', '<Leader>cs', function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(col + 1, col + 1)
  if char == '' then return end
  local before = line:sub(1, col)
  local after = line:sub(col + 2)
  vim.api.nvim_set_current_line(before .. '{~~ ' .. char .. ' ~>  ~~}' .. after)
  -- Cursor on space after ~> so user types the replacement
  vim.api.nvim_win_set_cursor(0, {row, col + #'{~~ ' + #char + #' ~> '})
  vim.cmd('startinsert')
end, { desc = 'CriticMarkup: substitute char' })

vim.keymap.set('v', '<Leader>cs', function()
  wrap_selection('{~~ ', ' ~>  ~~}', 4)
end, { desc = 'CriticMarkup: substitute' })
