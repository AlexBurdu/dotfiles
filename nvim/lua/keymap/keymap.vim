let mapleader = " " " Set leader to space

" Save and Quit
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>

" ### NAVIGATE ###
nnoremap <C-d> <C-d>zz
nnoremap <C-f> <C-f>zz
nnoremap <C-u> <C-u>zz
nnoremap <C-b> <C-b>zz

nnoremap n nzzzv
nnoremap N Nzzzv

" Switch Buffers / Tabs
if has('ide')
  nmap <S-h> m'<Action>(PreviousTab)
  nmap <S-l> m'<Action>(NextTab)
else 
  nnoremap <S-h> :bprevious<CR>
  nnoremap <S-l> :bnext<CR>
endif

" Splits
" Create splits
" https://linuxhandbook.com/split-vim-workspace/#resizing-split-windows
nnoremap <Leader><Leader>h :vsplit<CR>
nnoremap <Leader><Leader>l :vsplit<CR><C-w>r
nnoremap <Leader><Leader>k :split<CR>
nnoremap <Leader><Leader>j :split<CR><C-w>r

if !has('ide')
  " Allow navigating between splits in tmux when using netrw
  let g:tmux_navigator_disable_netrw_workaround = 1
  " g:Netrw_UserMaps is a list of lists. If you'd like to add other key mappings,
  " just add them like so: [['a', 'command1'], ['b', 'command2'], ...]
  let g:Netrw_UserMaps = [['<C-l>', '<C-U>TmuxNavigateRight<cr>']]
endif

" ### Edit ###
" Move selected lines while staying in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
" Join likes, but preserve cursor position
nnoremap J mzJ`z

" Yank and paste from global clipboard
nnoremap <Leader>y "*y
vnoremap <Leader>y "*y
nnoremap <Leader>Y "*Y
xnoremap <Leader>p "_dP
nnoremap <Leader>d "_d
vnoremap <Leader>d "_yd

" Replace thw word under cursor
nnoremap <Leader>r :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

" ### FORMAT ###
" Format the entire file
if has('ide')
  map <Leader><Leader>f <Action>(ReformatCode)zz
else
  nnoremap <Leader><Leader>f gg=G<C-o>zz
endif

" Clear search highlighting
nnoremap <C-n> :nohls<CR>

