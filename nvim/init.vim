call plug#begin('~/.vim/plugged')

    " Apperance Plugins
    Plug 'vim-airline/vim-airline'                   
    Plug 'vim-airline/vim-airline-themes'
    Plug 'ryanoasis/vim-devicons'
    Plug 'morhetz/gruvbox'
    Plug 'rainglow/vim'
    Plug 'romainl/Apprentice'

    " File, dir, term plugins
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-telescope/telescope.nvim'
    Plug 'preservim/nerdtree'
    Plug 'voldikss/vim-floaterm'

    " Language support
    Plug 'neoclide/coc.nvim', {'branch': 'release'}  
    Plug 'jiangmiao/auto-pairs'
    Plug 'terryma/vim-multiple-cursors'              
    Plug 'tpope/vim-commentary'                      
    Plug 'tpope/vim-fugitive'

call plug#end()

" Apperance
" colorscheme gruvbox
" colorscheme bold
colorscheme apprentice
let g:airline_theme='tomorrow'
syntax on

" Basic stuff to have
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

set timeout
set timeoutlen=200

" ------------------------------------------------------------------------------
" My remapps

" Remapping leader key
map <Space> <Nop>
let mapleader = " "

" Delete buffer for NERDTREE purposes
nnoremap <leader>bd :bp<cr>:bd #<cr>

" Move cursor to the end of the line
nnoremap <leader>p g_

" Move cursor to the begging of the line
nnoremap <leader>q ^

" Create under one empty line
nnoremap <leader>o o<ESC>k

" Copy from the cursor to the end of the line
nnoremap Y y$

" Change to uppercase
nnoremap <leader>u <C-v>U

" Change to lowercase
nnoremap <leader>i <C-v>u

" Save current file
nnoremap <Return> :w<CR>

" Indent multiple times       
vnoremap < <gv
vnoremap > >gv

" Mark word
nnoremap v ve

" Shortcut for esc
imap qf <esc>
vmap qf <esc>
nmap qf <esc>

" Moving between windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Move between buffers
nnoremap <leader>l :bp<CR>
nnoremap <leader>h :bn<CR>

" Telescope mappings
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fl <cmd>Telescope buffers<cr>
nnoremap <leader>fs <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fe <cmd>Telescope file_browser<cr>

" Nerdtree mappings
nnoremap <leader>nn :NERDTreeToggle<cr>
nnoremap <leader>nf :NERDTreeFind<cr>

" Compile
nnoremap <leader>m  :make %<<cr>

" Execute
nnoremap <leader>g :term %:p:r<cr>i

" Floaterm mapings for running gcc
" for change
nnoremap <leader>r :FloatermNew --autoclose=0 gcc % -o %< && ./%<<cr>
nnoremap <leader>rp :FloatermNew --autoclose=0 g++ % -o %< && ./%<<cr>

" Float term toggle
nnoremap <C-t> :FloatermToggle<cr><C-\><C-n>
tnoremap <C-t> <C-\><C-n>:FloatermToggle<CR>

" Use tab for autocompletion
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Choose autcomplete option with enter
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Show documentation
nnoremap <silent> K :call <SID>show_documentation()<CR>

" -----------------------------------------------------------------------------

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Function for tab
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Function for showing documentation
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Float term apperance
let g:floaterm_position="bottom"
let g:floaterm_width=0.6
let g:floaterm_height=0.6
hi FloatermBorder guifg=orange

" nerdtree settings
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeShowHidden=0
