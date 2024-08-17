" Mappings in this file are also loaded in IntelliJ IDEA IdeaVim
"
let mapleader = " " " Set leader to space

" Save and Quit
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>

" ### NAVIGATE ###
nnoremap <C-d> <C-d>zz
nnoremap <C-f> <C-f>zz
nnoremap <C-u> <C-u>zz
nnoremap <C-b> <C-b>zz

if !has('ide')
  " Open explorer (similar mapping to IntelliJ file tree)
  nnoremap <M-f> :Ex<CR>
  nnoremap <C-t> :Vex<CR>
endif

" Navigate to next/previous occurence but keep cursor centered
nnoremap n nzzzv
nnoremap N Nzzzv

" Switch Buffers 
nnoremap <S-h> :bprevious<CR>
nnoremap <S-l> :bnext<CR>

" Splits
" Create splits
" https://linuxhandbook.com/split-vim-workspace/#resizing-split-windows
nnoremap <Leader><Leader>h :vsplit<CR>
nnoremap <Leader><Leader>l :vsplit<CR><C-w>r
nnoremap <Leader><Leader>k :split<CR>
nnoremap <Leader><Leader>j :split<CR><C-w>r

" ### Edit ###
" Move selected lines while staying in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
" Join lines but preserve cursor position
nnoremap J mzJ`z

" Yank and paste from global clipboard
nnoremap <Leader>y "+y
vnoremap <Leader>y "+y
nnoremap <Leader>Y "+Y
xnoremap <Leader>p "_dP
vnoremap <Leader>p "_dP
nnoremap <Leader>d "_d
vnoremap <Leader>d "_yd

" Replace the word under cursor
nnoremap <Leader>r :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

" ### FORMAT ###
" Format the entire file
if has('ide')
  map <Leader><Leader>f <Action>(ReformatCode)zz
else
  nnoremap <Leader><Leader>f gg=G<C-o>zz
endif

" Keep selection after indenting
vnoremap < <gv
vnoremap > >gv

" Clear search highlighting
nnoremap <C-n> :nohls<CR>

