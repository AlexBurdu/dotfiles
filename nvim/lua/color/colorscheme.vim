" ### UI Settings###
let timehour = (strftime("%H"))
if timehour >= 19 || timehour < 5
  set background=dark
else
  set background=light
endif

" https://github.com/NLKNguyen/papercolor-theme
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
colorscheme PaperColor

" lua << EOF
" require("catppuccin").setup({
"     flavour = "auto", -- latte, frappe, macchiato, mocha
"     background = { -- :h background
"         light = "latte",
"         dark = "mocha",
"     },
"     color_overrides = {
"       mocha = {
"         base = "#000000", -- background color
"       }, 
"       latte = {
"         base = "#ffffff", -- background color
"       }
"     }
" })
" EOF
" colorscheme catppuccin

