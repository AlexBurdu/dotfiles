function vim.getVisualSelection()
  -- source: https://github.com/nvim-telescope/telescope.nvim/issues/1923
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg('v')
  vim.fn.setreg('v', {})

  text = string.gsub(text, "\n", "")
  if #text > 0 then
    return text
  else
    return ''
  end
end

return {
  "nvim-telescope/telescope.nvim",

  tag = "0.1.8",

  dependencies = {
    "nvim-lua/plenary.nvim"
  },

  config = function()
    -- https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#pickers
    require('telescope').setup({})
    local builtin = require('telescope.builtin')

    vim.keymap.set("n", "<Leader>e", builtin.buffers, {})
    vim.keymap.set("n", "<Leader>t", builtin.lsp_document_symbols, {})

    -- Find Files
    vim.keymap.set("n", "<Leader>f", builtin.find_files, {})
    vim.keymap.set("v", "<Leader>f", function ()
      local selection = vim.getVisualSelection()
      builtin.find_files({default_text = selection})
    end)
    -- Live Grep
    vim.keymap.set("n", "<Leader>g", builtin.live_grep, {})
    vim.keymap.set("v", "<Leader>g", function ()
      local selection = vim.getVisualSelection()
      builtin.live_grep({default_text = selection})
    end)
    vim.keymap.set("n", "<Leader>s", builtin.grep_string)

    -- LSP
    vim.keymap.set("n", "gd", builtin.lsp_definitions, {})
    vim.keymap.set("n", "<Leader>a", builtin.lsp_references)
    vim.keymap.set("n", "<Leader>i", builtin.lsp_implementations)
    vim.keymap.set("n", "<Leader>c", ":Telescope lsp_code_actions<CR>")
  end
}

