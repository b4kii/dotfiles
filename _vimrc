call plug#begin('~/.vim/plugged')

    Plug 'jiangmiao/auto-pairs'
    Plug 'terryma/vim-multiple-cursors'         "C-n
    Plug 'tpope/vim-commentary'                 "gcc


call plug#end()
 
syntax on
color desert

" hi Cursor guibg=yellow 

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
set cindent
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
set guicursor=n-v-c:block-blinkon700
set guicursor+=i:ver20-blinkoff0
set scrolloff=8
set showtabline=2

map <space> <nop>
let mapleader=" "

imap qf <esc>
nmap qf <esc>
vmap qf <esc>

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
nmap <S-h> :tabprev<cr>
nmap <S-l> :tabnext<cr>


nnoremap <leader>w :w<cr>
nnoremap <leader>o o<esc>k
nnoremap <leader>c :bd<cr>
nnoremap <leader>h :nohl

autocmd bufwritepre :tab ball<cr>

set lines=100
set columns=150
