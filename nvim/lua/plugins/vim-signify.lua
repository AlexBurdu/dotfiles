return {
  "mhinz/vim-signify",
  config = function()
    vim.keymap.set('n', '<Leader>vd', ':SignifyHunkDiff<CR>', { desc = 'Show hunk diff' })
    vim.keymap.set('n', '<Leader>vn', function()
      local sy = vim.b.sy
      if not sy or #sy.hunks == 0 then return end
      local lnum = vim.fn.line('.')
      for _, hunk in ipairs(sy.hunks) do
        if hunk.start > lnum then
          vim.fn.sign_jump(hunk.ids[1], '', vim.fn.bufname())
          return
        end
      end
      -- Wrap: jump to first hunk
      vim.fn.sign_jump(sy.hunks[1].ids[1], '', vim.fn.bufname())
    end, { desc = 'Next change hunk (wrapping)' })

    vim.keymap.set('n', '<Leader>vN', function()
      local sy = vim.b.sy
      if not sy or #sy.hunks == 0 then return end
      local lnum = vim.fn.line('.')
      for i = #sy.hunks, 1, -1 do
        if sy.hunks[i].start < lnum then
          vim.fn.sign_jump(sy.hunks[i].ids[1], '', vim.fn.bufname())
          return
        end
      end
      -- Wrap: jump to last hunk
      local last = sy.hunks[#sy.hunks]
      vim.fn.sign_jump(last.ids[1], '', vim.fn.bufname())
    end, { desc = 'Previous change hunk (wrapping)' })
  end
}
