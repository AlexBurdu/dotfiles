return {
  'Bekaboo/dropbar.nvim',
  config = function()
    local function step_bar(delta)
      local utils = require('dropbar.utils')
      local menu = utils.menu.get_current()
      if not menu then return end
      if delta < 0 and menu.prev_menu then
        menu:close()
        return
      end
      local root = menu:root()
      if not root or not root.prev_win then return end
      local bar = utils.bar.get({ buf = root.prev_buf, win = root.prev_win })
      if not bar or not bar.components then return end
      local cur_idx
      for i, comp in ipairs(bar.components) do
        if comp.menu == root then
          cur_idx = i
          break
        end
      end
      if not cur_idx then return end
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

    local function open_breadcrumb_picker()
      local bar = require('dropbar.utils').bar.get_current()
      if not bar or not bar.components or vim.tbl_isempty(bar.components) then
        return
      end
      for i = #bar.components, 1, -1 do
        local comp = bar.components[i]
        if comp.on_click and comp.opts and comp.opts.siblings and not vim.tbl_isempty(comp.opts.siblings) then
          bar:pick(i)
          return
        end
      end
      require('dropbar.api').pick()
    end

    require('dropbar').setup({
      menu = {
        win_configs = {
          height = function()
            return math.floor(vim.o.lines / 2)
          end,
        },
        keymaps = {
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
