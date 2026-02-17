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
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            preview_width = 0.5,
            width = 0.95,
          },
          vertical = {
            preview_height = 0.5,
          },
        },
        mappings = {
          i = {
            ["<C-j>"] = require('telescope.actions').move_selection_next,
            ["<C-k>"] = require('telescope.actions').move_selection_previous,
          },
        },
      },
    })
    local builtin = require('telescope.builtin')

    -- Try LSP, fall back to grep-based search when no LSP is available.
    local function lsp_or_fallback(lsp_fn, fallback_fn)
      return function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients > 0 then
          lsp_fn()
        else
          fallback_fn()
        end
      end
    end

    vim.keymap.set("n", "<Leader>e", function()
      builtin.oldfiles({ cwd_only = true })
    end, {})
    vim.keymap.set("n", "<Leader>t", lsp_or_fallback(
      builtin.lsp_document_symbols,
      builtin.current_buffer_fuzzy_find
    ), {})

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
    vim.keymap.set("n", "<Leader>fs", lsp_or_fallback(
      builtin.lsp_workspace_symbols,
      builtin.live_grep
    ))

    -- LSP with grep fallbacks
    vim.keymap.set("n", "gd", lsp_or_fallback(
      vim.lsp.buf.definition,
      function() builtin.grep_string({ word_match = '-w' }) end
    ), {})
    vim.keymap.set("n", "<Leader>fu", lsp_or_fallback(
      builtin.lsp_references,
      function() builtin.grep_string({ word_match = '-w' }) end
    ))
    vim.keymap.set("n", "<Leader>fi", lsp_or_fallback(
      builtin.lsp_implementations,
      function() builtin.grep_string({ word_match = '-w' }) end
    ))
    vim.keymap.set("n", "<Leader>fc", lsp_or_fallback(
      builtin.lsp_type_definitions,
      function() builtin.grep_string({ word_match = '-w' }) end
    ))
  end
}

