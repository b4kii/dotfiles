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

map <space> <nop>
let mapleader=" "

nnoremap Y y$
vnoremap < <gv
vnoremap > >gv

nnoremap zj o<esc>k
nnoremap zk O<esc>j

nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

nnoremap <M-h> :bp<cr>
nnoremap <M-l> :bn<cr>

nnoremap <leader>w :w<cr>
nnoremap <leader>q :bd<cr>
nnoremap <leader>h :nohl<cr>
nnoremap <leader>e :Ex<cr>

nnoremap <leader>gh 0
nnoremap <leader>gl $
nnoremap <leader>ge G

vnoremap <leader>gh 0
vnoremap <leader>gl $
vnoremap <leader>ge G

nnoremap <leader>rr :so %<cr>

augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=150})
augroup END

