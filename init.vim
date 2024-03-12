set relativenumber


set clipboard=unnamedplus
set scrolloff=10
set backspace=indent,eol,start
set guicursor=v-i:block
set encoding=utf-8
set tabstop=4
set shiftwidth=4
set softtabstop=4
set wildmenu
set incsearch
set nobackup
set noswapfile
set nowritebackup
set noundofile
          
color desert

map <space> <nop>
let mapleader=" "

nnoremap Y y$
vnoremap < <gv
vnoremap > >gv
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <C-Down> :move .+1<cr>==
nnoremap <C-Up> :move .-2<cr>==
vnoremap <C-Down> :move '>+1<cr>gv=gv
vnoremap <C-Up> :move '<-2<cr>gv=gv
map <C-d> <C-d>zz
map <C-u> <C-u>zz

nmap <S-h> :bp<cr>
nmap <S-l> :bn<cr>

nnoremap <leader>w :w<cr>
nnoremap <leader>c :bd<cr>
nnoremap <leader>h :nohl<cr>
nnoremap <leader>e :Ex<cr>

nnoremap zj o<esc>k
nnoremap zk O<esc>j

augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=150})
augroup END

