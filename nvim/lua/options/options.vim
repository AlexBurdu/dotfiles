" Ignore Case for search
set ignorecase
set smartcase
" Highlight search (incremental)
set hls is

" Customize the color of highlighted text
if !has('ide')
  " Code Formatting
  " Set indentation to 2 spaces
  set autoindent expandtab tabstop=2 shiftwidth=2
endif
" Always show line numbers
set number
set relativenumber

" Override netwrw settings to show line numbers
let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'
