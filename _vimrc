call plug#begin('~/.vim/plugged')
    Plug 'jiangmiao/auto-pairs'
    Plug 'terryma/vim-multiple-cursors'         "C-n
    Plug 'tpope/vim-commentary'                 "gcc
    Plug 'ayu-theme/ayu-vim'
call plug#end()
 
syntax on

let ayucolor="mirage"
color ayu

hi Cursor guibg=yellow 

set number
set relativenumber
set mouse=a
set encoding=utf-8
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
set autoindent
set backspace=indent,eol,start
set clipboard=unnamed
set history=1000
set wildmenu
set incsearch
set nobackup
set noswapfile
set nowritebackup
set noundofile
set nowrap
set hidden
set timeout
set timeoutlen=200
set guioptions-=m
set guioptions-=T
set guicursor=a:block
set scrolloff=8
set showtabline=2
set guifont=JetBrains\ Mono\ NL:h11

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
set lines=35
set columns=120

let g:netrw_browse_split = 0
let g:netrw_banner = 0
let g:netrw_winsize = 25
