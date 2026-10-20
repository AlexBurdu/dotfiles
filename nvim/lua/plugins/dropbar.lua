-- Winbar breadcrumbs and keyboard-driven breadcrumb picker (`dropbar.nvim`).
--
-- Mirrors IntelliJ's Navigation Bar (`ShowNavBar`) and VS Code's Breadcrumbs
-- picker (`breadcrumbs.focusAndSelect`):
--   - `<C-t>` / `<Leader><Leader>t`: open the dropdown menu for the rightmost
--     breadcrumb that has siblings.
--   - `h` / `<C-h>` / `l` / `<C-l>`: step to the previous / next breadcrumb on
--     the winbar (or close a nested submenu on `h` / `<C-h>`).
--   - `j` / `k` / `<C-j>` / `<C-k>`: move down / up inside the open dropdown menu.
--   - `<CR>` / `<C-CR>`: unfold a folder/symbol submenu or open the selected
--     file / jump to the selected symbol.
--   - `q` / `<Esc>`: close the breadcrumb menu.
return {
  'Bekaboo/dropbar.nvim',
  config = function()
    --- Move the active picker to an adjacent winbar breadcrumb (`delta = -1` for
    --- previous, `delta = 1` for next).
    ---
    --- While a dropbar menu float is open, the float itself is the current window,
    --- so `utils.bar.get_current()` returns `nil`. Looking up the bar via the root
    --- menu's parent window (`root.prev_win`) locates the underlying editor
    --- window's winbar so we can close the current menu and open the adjacent
    --- crumb's menu in one keystroke.
    ---@param delta integer Direction and step count along `bar.components` (-1 or +1).
    local function step_bar(delta)
      local utils = require('dropbar.utils')
      local menu = utils.menu.get_current()
      if not menu then return end

      -- When inside a nested child submenu (unfolded via `<CR>`), stepping left
      -- collapses back to the parent menu instead of jumping to the previous
      -- top-level winbar breadcrumb.
      if delta < 0 and menu.prev_menu then
        menu:close()
        return
      end

      -- Walk up to the top-level menu to find the editor window (`prev_win`)
      -- that owns the winbar.
      local root = menu:root()
      if not root or not root.prev_win then return end
      local bar = utils.bar.get({ buf = root.prev_buf, win = root.prev_win })
      if not bar or not bar.components then return end

      -- Find which winbar breadcrumb component currently owns the open root menu.
      local cur_idx
      for i, comp in ipairs(bar.components) do
        if comp.menu == root then
          cur_idx = i
          break
        end
      end
      if not cur_idx then return end

      -- Scan in direction `delta` for the next breadcrumb component that has a
      -- non-empty sibling list, close the current menu tree, and open the target
      -- breadcrumb's dropdown immediately.
      local target_idx = cur_idx + delta
      while target_idx >= 1 and target_idx <= #bar.components do
        local comp = bar.components[target_idx]
        if comp.on_click and comp.opts and comp.opts.siblings and not vim.tbl_isempty(comp.opts.siblings) then
          root:close()
          bar:pick(target_idx)
          return
        end
        target_idx = target_idx + delta
      end
    end

    --- Open the breadcrumb dropdown menu directly on the rightmost clickable
    --- winbar component (typically the current symbol or filename) without
    --- requiring a two-step visual label-selection pass first.
    local function open_breadcrumb_picker()
      local bar = require('dropbar.utils').bar.get_current()
      if not bar or not bar.components or vim.tbl_isempty(bar.components) then
        return
      end
      -- Walk backward from the end of the winbar to pick the deepest crumb that
      -- can open a sibling menu.
      for i = #bar.components, 1, -1 do
        local comp = bar.components[i]
        if comp.on_click and comp.opts and comp.opts.siblings and not vim.tbl_isempty(comp.opts.siblings) then
          bar:pick(i)
          return
        end
      end
      -- Fall back to interactive label selection if no component exposes siblings.
      require('dropbar.api').pick()
    end

    --- Activate the first clickable component on the current menu line.
    --- For directories or container symbols with children, this unfolds the child
    --- submenu; for leaf files or symbols, it opens the file or jumps to the range.
    local function activate_entry()
      local utils = require('dropbar.utils')
      local menu = utils.menu.get_current()
      if not menu then return end
      local cursor = vim.api.nvim_win_get_cursor(menu.win)
      local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
      if component then
        menu:click_on(component, nil, 1, 'l')
      end
    end

    require('dropbar').setup({
      menu = {
        win_configs = {
          height = function()
            return math.floor(vim.o.lines / 2)
          end,
        },
        keymaps = {
          -- Unfold directory/submenu or open file/symbol (`<C-CR>` matches `<CR>`
          -- when Control is still held from `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>`).
          ['<CR>'] = activate_entry,
          ['<C-CR>'] = activate_entry,
          -- Step to the previous / next winbar breadcrumb (or close a child submenu).
          ['h'] = function() step_bar(-1) end,
          ['<C-h>'] = function() step_bar(-1) end,
          ['l'] = function() step_bar(1) end,
          ['<C-l>'] = function() step_bar(1) end,
          ['<C-j>'] = 'j',
          ['<C-k>'] = 'k',
          ['q'] = function() require('dropbar.utils').menu.exec('close') end,
          ['<Esc>'] = function() require('dropbar.utils').menu.exec('close') end,
        },
      },
    })
    -- C-t / <Leader><Leader>t to pick from breadcrumb (like IntelliJ ShowNavBar)
    vim.keymap.set('n', '<C-t>', open_breadcrumb_picker, { desc = 'Pick from breadcrumb' })
    vim.keymap.set('n', '<Leader><Leader>t', open_breadcrumb_picker, { desc = 'Pick from breadcrumb' })
  end
}
