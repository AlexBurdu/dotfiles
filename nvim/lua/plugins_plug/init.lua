local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin')

Plug('https://github.com/chaoren/vim-wordmotion.git')

-- Themes
Plug('https://github.com/NLKNguyen/papercolor-theme.git')
Plug('catppuccin/nvim', {as = 'catppuccin'})

-- https://github.com/christoomey/vim-tmux-navigator
Plug('christoomey/vim-tmux-navigator')

Plug('nvim-lua/plenary.nvim')
Plug('nvim-telescope/telescope.nvim', { ['tag'] = '0.1.5' })

-- Dynamically load all plugins in the plugins directory
-- Each file should be a lua module that returns a function that loads plugins
-- using Plug(), similar to the above examples
local plugins = vim.fn.glob("$HOME/.config/nvim/lua/plugins_plug/*.lua", 0, 1)
for _, plugin in ipairs(plugins) do
  if plugin:match("plugins_plug/init.lua") == nil then -- if not init.lua
    -- Pass the Plug function to the plugin module
    require('plugins_plug.' .. plugin:match("plugins_plug/(.*)"):gsub(".lua", ""))(Plug)
  end
end

vim.call('plug#end')
