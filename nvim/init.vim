call plug#begin('~/.vim/plugged')

    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-telescope/telescope.nvim'
    Plug 'jiangmiao/auto-pairs'
    Plug 'terryma/vim-multiple-cursors'         "C-n
    Plug 'tpope/vim-commentary'                 "gcc
    Plug 'preservim/nerdtree'
    " Plug 'gruvbox-community/gruvbox'
    " Plug 'sainnhe/sonokai'
    Plug 'sainnhe/everforest'

call plug#end()

syntax on

set termguicolors
set mouse=a
set guicursor=a:block-blinkoff0
set nu
set relativenumber
set showcmd
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
set nowrap
set scrolloff=8
set path+=**
set wildmenu
set signcolumn=yes
set nohlsearch
set incsearch
set nobackup
set noswapfile

map <Space> <Nop>
let mapleader = " "

map <S-h> :w<CR>:bp<CR>

map <S-l> :w<CR>:bn<CR>

nnoremap <leader>o o<ESC>k

nnoremap Y y$

nnoremap <Return> :w<CR>

nnoremap <leader>p g_

nnoremap <leader>q ^

imap qf <esc>
xmap qf <esc>

nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fs <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fa :lua require('telescope.builtin').file_browser()<cr>

nnoremap <leader>nn :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>

let NERDTreeAutoDeleteBuffer = 1

let g:airline_wombat='base16'

colorscheme everforest
let g:everforest_background = 'hard'

let g:everforest_background = 'hard'

