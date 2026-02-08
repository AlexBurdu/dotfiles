" ### UI Settings###
set cursorline

" Detect OS dark/light mode (consistent with tmux/set-themes.sh)
function! s:IsDarkMode()
  if has('mac')
    " macOS: returns "Dark" if dark mode is enabled
    let l:result = system('defaults read -g AppleInterfaceStyle 2>/dev/null')
    return l:result =~# 'Dark'
  else
    " Linux/GNOME: check color-scheme setting
    let l:result = system('gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null')
    return l:result =~# 'dark'
  endif
endfunction

if s:IsDarkMode()
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

  " Update focus colors and highlights when colorscheme changes
  " (e.g., when tmux switches theme via :colorscheme command)
  autocmd ColorScheme carbonfox call s:SetCarbonfoxColors()
  autocmd ColorScheme dayfox call s:SetDayfoxColors()
augroup END

" Dark theme: black background with dark gray dimming
function! s:SetCarbonfoxColors()
  let g:focus_normal_bg = '#000000'  " focused bg (black)
  let g:focus_dimmed_bg = '#111111'  " unfocused bg (dark gray)
  highlight Normal guibg=#000000     " set focused split bg
  highlight NormalNC guibg=#111111   " set unfocused split bg
endfunction

" Light theme: light gray background with darker gray dimming
function! s:SetDayfoxColors()
  let g:focus_normal_bg = '#f0f1f7'  " focused bg (light gray)
  let g:focus_dimmed_bg = '#e0e1e7'  " unfocused bg (darker gray)
  highlight Normal guibg=#f0f1f7     " set focused split bg
  highlight NormalNC guibg=#e0e1e7   " set unfocused split bg
endfunction

