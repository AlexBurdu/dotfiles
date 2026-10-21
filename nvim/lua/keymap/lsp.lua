-- LSP keybindings (mirrors IntelliJ <Leader>s* and refactoring patterns)
vim.keymap.set('n', '<Leader>se', vim.diagnostic.open_float, { desc = 'Show error description' })
vim.keymap.set('n', '<Leader>sh', vim.lsp.buf.hover, { desc = 'Show hover documentation' })
vim.keymap.set('n', '<Leader>st', vim.lsp.buf.hover, { desc = 'Show expression type / hover info' })
vim.keymap.set('n', '<Leader>sp', vim.lsp.buf.signature_help, { desc = 'Show parameter signature help' })
vim.keymap.set('n', '<Leader>n', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<Leader>N', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set({ 'n', 'v' }, '<Leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })
vim.keymap.set({ 'n', 'v' }, '<Leader><Leader>r', vim.lsp.buf.code_action, { desc = 'Refactorings / code actions' })
vim.keymap.set('n', '<Leader><Leader>m', '<cmd>popup PopUp<CR>', { desc = 'Show popup context menu' })

vim.keymap.set('n', '<Leader><Leader>f', function()
  local pos = vim.api.nvim_win_get_cursor(0)
  local conform = require("conform")
  local has_formatter = vim.iter(conform.list_formatters()):any(function(f) return f.available end)
  if has_formatter then
    conform.format({ async = false })
  elseif #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/formatting' }) > 0 then
    vim.lsp.buf.format()
  else
    vim.cmd('normal! gg=G')
  end
  vim.api.nvim_win_set_cursor(0, pos)
  vim.cmd('normal! zz')
end, { desc = 'Format file (conform → LSP → indent fallback)' })
