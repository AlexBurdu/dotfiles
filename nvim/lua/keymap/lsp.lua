-- LSP keybindings (mirrors IntelliJ <Leader>s* pattern)
vim.keymap.set('n', '<Leader>se', vim.diagnostic.open_float, { desc = 'Show error description' })
vim.keymap.set('n', '<Leader>sh', vim.lsp.buf.hover, { desc = 'Show hover documentation' })
vim.keymap.set('n', '<Leader>n', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<Leader>N', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })

vim.keymap.set('n', '<Leader><Leader>f', function()
  local clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/formatting' })
  if #clients > 0 then
    vim.lsp.buf.format()
  else
    vim.cmd('normal! gg=G\15')  -- \15 = <C-o>
  end
  vim.cmd('normal! zz')
end, { desc = 'Format file (LSP or indent fallback)' })
