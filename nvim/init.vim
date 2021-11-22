call plug#begin('~/.vim/plugged')

    Plug 'vim-airline/vim-airline'                   " status bar
    Plug 'vim-airline/vim-airline-themes'

    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-telescope/telescope.nvim'

    Plug 'neoclide/coc.nvim', {'branch': 'release'}  
    Plug 'jiangmiao/auto-pairs'
    Plug 'terryma/vim-multiple-cursors'              " C-n
    Plug 'tpope/vim-commentary'                      " gcc
    Plug 'preservim/nerdtree'
    Plug 'tpope/vim-fugitive'

    Plug 'ryanoasis/vim-devicons'
    Plug 'morhetz/gruvbox'

call plug#end()

colorscheme gruvbox
let g:airline_theme='tomorrow'

syntax on

set termguicolors
set mouse=a
set guicursor=a:block-blinkoff0
set nu
set relativenumber
set showcmd
set cmdheight=2
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
set wildmenu
set signcolumn=yes
set nohlsearch
set incsearch
set nobackup
set noswapfile
set hidden

" remapping leader key
map <Space> <Nop>
let mapleader = " "

" move between buffers
nnoremap <leader>l :bp<CR>
nnoremap <leader>h :bn<CR>

" delete buffer
nnoremap <leader>bd :bp<cr>:bd #<cr>

" move cursor to the end of the line
nnoremap <leader>p g_

" move cursor to the begging of the line
nnoremap <leader>q ^

" create under one empty line
nnoremap <leader>o o<ESC>k

" copy from the cursor to the end of the line
nnoremap Y y$

" save current file
nnoremap <Return> :w<CR>

" indent multiple times       
vnoremap < <gv
vnoremap > >gv

" mark word
nnoremap v ve

" shortcut for esc
imap qf <esc>
xmap qf <esc>
nmap qf <esc>

" moving between windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" telescope mappings
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fs <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fa :lua require('telescope.builtin').file_browser()<cr>

" nerdtree mappings
nnoremap <leader>nn :NERDTreeToggle<cr>
nnoremap <leader>nf :NERDTreeFind<cr>

let NERDTreeAutoDeleteBuffer = 1
let NERDTreeShowHidden=0

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" coc clangd mappings
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Compile
nnoremap <leader>m  :make %<<cr>
" Execute
nnoremap <leader>r :term %:p:r<cr>i
