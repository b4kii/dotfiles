 call plug#begin('~/.vim/plugged')

    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'jiangmiao/auto-pairs'
    Plug 'terryma/vim-multiple-cursors'         "C-n
    Plug 'tpope/vim-commentary'                 "gcc
    Plug 'preservim/nerdtree'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'voldikss/vim-floaterm'

call plug#end()
 
syntax on

color evening
let g:airline_theme='term'

hi Cursor guibg=yellow 
hi Normal guibg=#282828
hi NonText guibg=#282828
hi Pmenu guibg=#fbf1c7 guifg=#282828
hi PmenuSel guibg=#bdae93 guifg=#282828
hi PreProc guifg=#fabd2f
hi Identifier guifg=#60ff60
hi Constant guifg=#f2e5bc

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
set nohlsearch
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
set guicursor+=i:block-blinkoff0
set scrolloff=8

map <space> <nop>
let mapleader=" "

imap qf <esc>
nmap qf <esc>
vmap qf <esc>

nnoremap Y y$
nnoremap <return> :w<cr>
vnoremap < <gv
vnoremap > >gv
nnoremap <C-h> <C-h>h
nnoremap <C-j> <C-j>j
nnoremap <C-k> <C-k>k
nnoremap <C-l> <C-l>l
nnoremap <C-Down> :move .+1<cr>==
nnoremap <C-Up> :move .-2<cr>==
vnoremap <C-Down> :move '>+1<cr>gv=gv
vnoremap <C-Up> :move '<-2<cr>gv=gv

nnoremap <leader>o o<esc>k
nnoremap <leader>, :bp<cr>
nnoremap <leader>. :bn<cr>
nnoremap <leader>l g_
nnoremap <leader>h ^
nnoremap <leader>u <C-v>U
vnoremap <leader>u <C-v>U
nnoremap <leader>i <C-v>u
vnoremap <leader>i <C-v>u

nnoremap <C-f> <cmd>FZF<cr>
nnoremap <leader>b <cmd>Buffers<cr>
nnoremap <leader>/ <cmd>Lines<cr>
nnoremap <leader>fg <cmd>Rg<cr>

let g:fzf_layout={'up': '40%'}

" Float term toggle
nnoremap <C-t> :FloatermToggle<cr><C-\><C-n>
tnoremap <C-t> <C-\><C-n>:FloatermToggle<CR>

" Float term apperance
let g:floaterm_wintype="split"
" let g:floaterm_position="bottom"
let g:floaterm_width=0.5
let g:floaterm_height=0.5
hi FloatermBorder guifg=lightblue
