-- Telescope is a fuzzy finder for Neovim, allowing you to search and filter
-- files, buffers, and more.
-- https://github.com/nvim-telescope/telescope.nvim
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

  tag = "v0.2.1",

  dependencies = {
    "nvim-lua/plenary.nvim"
  },

  config = function()
    -- https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#pickers
    require('telescope').setup({
      defaults = {
        path_display = { "filename_first" },
        mappings = {
          i = {
            ["<C-j>"] = require('telescope.actions').move_selection_next,
            ["<C-k>"] = require('telescope.actions').move_selection_previous,
          },
        },
      },
    })
    local builtin = require('telescope.builtin')

    vim.keymap.set("n", "<Leader>e", function()
      builtin.oldfiles({ cwd_only = true })
    end, {})
    vim.keymap.set("n", "<Leader>t", builtin.lsp_document_symbols, {})

    -- Find Files
    vim.keymap.set("n", "<Leader>ff", builtin.find_files, {})
    vim.keymap.set("v", "<Leader>ff", function ()
      local selection = vim.getVisualSelection()
      builtin.find_files({default_text = selection})
    end)
    -- Live Grep / Find in Path
    vim.keymap.set("n", "<Leader>fp", builtin.live_grep, {})
    vim.keymap.set("v", "<Leader>fp", function ()
      local selection = vim.getVisualSelection()
      builtin.live_grep({default_text = selection})
    end)
    vim.keymap.set("n", "<Leader>fs", builtin.lsp_workspace_symbols)

    -- LSP (use native vim.lsp for gd due to telescope + nvim 0.11 bug)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
    vim.keymap.set("n", "<Leader>fu", builtin.lsp_references)
    vim.keymap.set("n", "<Leader>fi", builtin.lsp_implementations)
    vim.keymap.set("n", "<Leader>fc", builtin.lsp_type_definitions)
  end
}

