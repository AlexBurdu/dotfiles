return {
  'Bekaboo/dropbar.nvim',
  config = function()
    require('dropbar').setup({
      menu = {
        win_configs = {
          height = function()
            return math.floor(vim.o.lines / 2)
          end,
        },
        keymaps = {
          ['<C-h>'] = function()
            local menu = require('dropbar.api').get_current_dropbar_menu()
            if menu then menu:close() end
          end,
          ['<C-j>'] = 'j',
          ['<C-k>'] = 'k',
          -- C-l needs custom function to replicate Enter behavior
          ['<C-l>'] = function()
            local menu = require('dropbar.api').get_current_dropbar_menu()
            if not menu then return end
            local cursor = vim.api.nvim_win_get_cursor(menu.win)
            local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
            if component then
              menu:click_on(component, nil, 1, 'l')
            end
          end,
        },
      },
    })
    -- C-t to pick from breadcrumb (like IntelliJ ShowNavBar)
    vim.keymap.set('n', '<C-t>', require('dropbar.api').pick, { desc = 'Pick from breadcrumb' })
  end
}
