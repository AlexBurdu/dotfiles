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

-- Conditional loading of work or personal plugins (Vimscript)
local work_plugins_path = vim.fn.expand("$HOME/.config/nvim/lua/plugins/work_plugins.lua")
local personal_plugins_path = vim.fn.expand("$HOME/.config/nvim/lua/plugins/personal_plugins.vim")

if vim.fn.filereadable(work_plugins_path) ~= 0 then
  require('plugins.work_plugins')()
end
if vim.fn.filereadable(personal_plugins_path) ~=0 then
  require('plugins.personal')()
end

vim.call('plug#end')
