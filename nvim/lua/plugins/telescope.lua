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
            ["<C-y>"] = function(prompt_bufnr)
              local preview_win = require('telescope.state').get_status(prompt_bufnr).preview_win
              if preview_win and vim.api.nvim_win_is_valid(preview_win) then
                vim.api.nvim_win_call(preview_win, function() vim.cmd([[execute "normal! \<C-y>"]]) end)
              end
            end,
            ["<C-e>"] = function(prompt_bufnr)
              local preview_win = require('telescope.state').get_status(prompt_bufnr).preview_win
              if preview_win and vim.api.nvim_win_is_valid(preview_win) then
                vim.api.nvim_win_call(preview_win, function() vim.cmd([[execute "normal! \<C-e>"]]) end)
              end
            end,
          },
          n = {
            ["<C-j>"] = require('telescope.actions').move_selection_next,
            ["<C-k>"] = require('telescope.actions').move_selection_previous,
            ["<C-y>"] = function(prompt_bufnr)
              local results_win = require('telescope.state').get_status(prompt_bufnr).results_win
              if results_win and vim.api.nvim_win_is_valid(results_win) then
                vim.api.nvim_win_call(results_win, function() vim.cmd([[execute "normal! \<C-y>"]]) end)
              end
            end,
            ["<C-e>"] = function(prompt_bufnr)
              local results_win = require('telescope.state').get_status(prompt_bufnr).results_win
              if results_win and vim.api.nvim_win_is_valid(results_win) then
                vim.api.nvim_win_call(results_win, function() vim.cmd([[execute "normal! \<C-e>"]]) end)
              end
            end,
            ["<C-u>"] = function(prompt_bufnr)
              local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
              local half = math.floor(vim.api.nvim_win_get_height(picker.results_win) / 2)
              picker:move_selection(-half)
            end,
            ["<C-d>"] = function(prompt_bufnr)
              local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
              local half = math.floor(vim.api.nvim_win_get_height(picker.results_win) / 2)
              picker:move_selection(half)
            end,
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
    -- Document symbols with hierarchy (heading markers for markdown, indentation for code)
    vim.keymap.set("n", "<Leader>t", function()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then
        builtin.current_buffer_fuzzy_find()
        return
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local cursor_lnum = vim.api.nvim_win_get_cursor(0)[1]
      local is_md = vim.bo[bufnr].filetype == 'markdown'
      local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

      vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result)
        if err or not result or vim.tbl_isempty(result) then return end

        local items = {}
        local kind_names = vim.lsp.protocol.SymbolKind
        local function flatten(symbols, depth)
          for _, s in ipairs(symbols) do
            local range = s.selectionRange or s.range
            local display
            if is_md then
              display = string.rep('#', depth + 1) .. ' ' .. s.name
            else
              local kind = kind_names[s.kind] or ''
              display = string.rep('  ', depth) .. kind .. '  ' .. s.name
            end
            table.insert(items, {
              display = display,
              name = s.name,
              lnum = range.start.line + 1,
              col = range.start.character + 1,
            })
            if s.children then flatten(s.children, depth + 1) end
          end
        end
        flatten(result, 0)

        local best_idx = 1
        local best_lnum = -1
        for i, item in ipairs(items) do
          if item.lnum <= cursor_lnum and item.lnum > best_lnum then
            best_lnum = item.lnum
            best_idx = i
          end
        end

        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        local fname = vim.api.nvim_buf_get_name(bufnr)

        pickers.new({
          layout_strategy = 'horizontal',
          layout_config = {
            preview_width = 0.5,
            width = 0.95,
            prompt_position = 'top',
          },
          sorting_strategy = 'ascending',
        }, {
          prompt_title = 'Document Symbols',
          finder = finders.new_table({
            results = items,
            entry_maker = function(item)
              return {
                value = item,
                display = item.display,
                ordinal = item.name,
                lnum = item.lnum,
                col = item.col,
                filename = fname,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          previewer = conf.grep_previewer({}),
          on_complete = {
            function(picker)
              picker:set_selection(best_idx - 1)
            end,
          },
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local sel = action_state.get_selected_entry()
              if sel then
                vim.api.nvim_win_set_cursor(0, { sel.lnum, sel.col - 1 })
              end
            end)
            return true
          end,
        }):find()
      end)
    end, {})

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

