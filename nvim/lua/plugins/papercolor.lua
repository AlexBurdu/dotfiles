return {
-- https://github.com/NLKNguyen/papercolor-theme
  "NLKNguyen/papercolor-theme",

  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins

  config = function()
    vim.cmd([[
  let g:PaperColor_Theme_Options = {
    \   'theme': {
    \     'default.light': {
    \       'override' : {
    \         'color00' : ['#ffffff', '256'],
    \         'linenumber_bg' : ['#ffffff', '256']
    \       }
    \     },
    \     'default.dark': {
    \       'override' : {
    \         'color00' : ['#000000', '000'],
    \         'linenumber_bg' : ['#000000', '000'],
    \         'color03' : ['#5faf00', '70'],
    \       }
    \     }
    \   }
    \ }
    ]])
    -- load the colorscheme here
    vim.cmd([[colorscheme PaperColor]])
  end,
}
