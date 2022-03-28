call plug#begin('~/.vim/plugged')

    " Apperance Plugins
    Plug 'vim-airline/vim-airline'                   
    Plug 'vim-airline/vim-airline-themes' 
    Plug 'ryanoasis/vim-devicons'
    Plug 'yeddaif/neovim-purple'
    Plug 'arcticicestudio/nord-vim'

    " File, dir, term plugins
    Plug 'preservim/nerdtree'
    Plug 'voldikss/vim-floaterm'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Language support
    Plug 'neoclide/coc.nvim', {'branch': 'release'}  
    Plug 'jiangmiao/auto-pairs'
    Plug 'terryma/vim-multiple-cursors'              
    Plug 'tpope/vim-commentary'                      
    Plug 'tpope/vim-fugitive'

call plug#end()

syntax on

" Theme
" colorscheme evening
colorscheme nord

" Status line
let g:airline_theme='wombat'

" Basic stuff to have
set termguicolors 
set guicursor=i:block-Cursor-blinkoff0
set guicursor+=n-v-c:block-Cursor-blinkon1
set lazyredraw
set mouse=a
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
" Leader remaps

" Remapping leader key
map <Space> <Nop>
let mapleader = " "

" Delete buffer for NERDTREE purposes
nnoremap <leader>bd :bp<cr>:bd #<cr>

" Create under one empty line
nnoremap <leader>o o<ESC>k

" FZF 
nnoremap <C-f> <cmd>FZF<cr>
nnoremap <leader>b <cmd>Buffers<cr>
nnoremap <leader>/ <cmd>Lines<cr>
nnoremap <leader>fg <cmd>Rg<cr>

" Nerdtree 
nnoremap <leader>nn :NERDTreeToggle<cr>
nnoremap <leader>nf :NERDTreeFind<cr>

" Floaterm mapings for running gcc
" for change
nnoremap <leader>r :FloatermNew --autoclose=0 gcc % -o %< && ./%<<cr>
nnoremap <leader>rp :FloatermNew --autoclose=0 g++ % -o %< && ./%<<cr>

" Moving lines 
nnoremap <C-Down> :move .+1<cr>==
nnoremap <C-Up> :move .-2<cr>==
vnoremap <C-Down> :move '>+1<cr>gv=gv
vnoremap <C-Up> :move '<-2<cr>gv=gv

" Move between buffers
nnoremap <leader>m :bp<CR>
nnoremap <leader>, :bn<CR>

" Normal remaps
" ----------------------------------------------------------------------------------------

" Shortcut for esc
imap qf <esc>
vmap qf <esc>
nmap qf <esc>

" Copy from the cursor to the end of the line
nnoremap Y y$

" Save current file
nnoremap <Return> :w<CR>

" Indent multiple times       
vnoremap < <gv
vnoremap > >gv

" Moving between windows
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

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
let g:floaterm_wintype="float"
let g:floaterm_width=0.8
let g:floaterm_height=0.5
let g:floaterm_position="bottom"
hi FloatermBorder guifg=lightblue

" Nerdtree settings
let NERDTreeAutoDeleteBuffer=1
let NERDTreeShowHidden=0

" Fzf apperance
let g:fzf_layout={'up': '40%'}

" Apperance
hi Cursor guibg=yellow 
hi Normal guibg=#282828
hi NonText guibg=#282828
hi Pmenu guibg=#fbf1c7 guifg=#282828
hi PmenuSel guibg=#bdae93 guifg=#282828
" hi PreProc guifg=#fabd2f
" hi Identifier guifg=#ffc0cb
" hi Constant guifg=#f2e5bc

filetype indent off