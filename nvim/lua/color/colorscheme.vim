" ### UI Settings###
set cursorline
let timehour = (strftime("%H"))
if timehour >= 20 || timehour < 5
  set background=dark
  colorscheme carbonfox
  " Background colors for focus dimming (matches custom carbonfox bg1 / slightly lighter)
  let g:focus_normal_bg = '#000000'
  let g:focus_dimmed_bg = '#111111'
else
  set background=light
  colorscheme dayfox
  " Background colors for focus dimming (matches custom dayfox bg1 / slightly darker)
  let g:focus_normal_bg = '#f0f1f7'
  let g:focus_dimmed_bg = '#e0e1e7'
endif

" Dim inactive nvim splits via NormalNC (non-current window highlight).
" Also dim all splits when the tmux pane loses focus via FocusLost/FocusGained
" (requires focus-events on in tmux). This complements tmux's window-style dimming
" which only affects plain terminal panes, since nvim paints its own background.
execute 'highlight NormalNC guibg=' . g:focus_dimmed_bg
augroup FocusDim
  autocmd!
  autocmd FocusLost * execute 'highlight Normal guibg=' . g:focus_dimmed_bg
  autocmd FocusGained * execute 'highlight Normal guibg=' . g:focus_normal_bg
augroup END

