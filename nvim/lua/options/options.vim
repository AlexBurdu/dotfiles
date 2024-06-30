" Ignore Case for search
set ignorecase
set smartcase
" Highlight search (incremental)
set nohlsearch
set incsearch

set tabstop=2 softtabstop=2 shiftwidth=2
set expandtab
set autoindent
set smartindent

" Always show line numbers
set number
set relativenumber
set nowrap

set scrolloff=10

set noswapfile
set nobackup
if !has('ide')
  set undodir=~/.vim/undodir
  set undofile
endif

" Override netwrw settings to show line numbers
let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'
