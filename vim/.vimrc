call plug#begin('~/.vim/plugged')
" vim plugs
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme="deus"
Plug 'miyakogi/seiya.vim'
Plug 'jiangmiao/auto-pairs'
" let g:seiya_auto_enable=1
" let g:seiya_target_groups = has('nvim') ? ['guibg'] : ['ctermbg']
Plug 'scrooloose/nerdcommenter'
let g:NERDSpaceDelims=1 " always insert spaces after commenting
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'scrooloose/nerdtree'
let NERDTreeShowHidden=1
Plug 'liuchengxu/vista.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-tsserve',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-json', 
  \ ]
" devtools / dev setup
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'rust-lang/rust.vim'
Plug 'tomlion/vim-solidity'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html', 'solidity', 'php', 'swift', 'python', 'ruby'] }
Plug 'gorodinskiy/vim-coloresque'
Plug 'psf/black'
Plug 'dense-analysis/ale'
let g:ale_fix_on_save=1
Plug 'othree/yajs.vim'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
" colorschemes
Plug 'kaicataldo/material.vim'
Plug 'whatyouhide/vim-gotham'
Plug 'jeffkreeftmeijer/vim-dim'
Plug 'chriskempson/base16-vim'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'liuchengxu/space-vim-theme'
Plug 'jaredgorski/spacecamp'
Plug 'sjl/badwolf'
Plug 'haishanh/night-owl.vim'
Plug 'micha/vim-colors-solarized'
Plug 'crusoexia/vim-monokai'
Plug 'mhartington/oceanic-next'
Plug 'challenger-deep-theme/vim', { 'as': 'challenger-deep' }
call plug#end()

:set guicursor=a:blinkon100

set number
set tabstop=2 " tab width = 4, (only interpretation)
set softtabstop=2 " useful for python, for example
set shiftwidth=2 " indents -> width 4
set expandtab "expand tab to space
set guifont=SF\ Mono\ Nerd\ Font:h14
set hlsearch
set cursorline
set autoread
set mouse=i
" S for saving
noremap S :update<CR>
" Q for leaving
noremap Q :q<CR>
" Make exiting to normal mode a bit easier
imap <leader><leader> <Esc>
syntax enable
" for vim 7
set t_Co=256
" for vim 8
 if (has("termguicolors"))
  set termguicolors
 endif

set termguicolors
colorscheme material
" File types handling
" Enable filetype detection:
filetype on
filetype plugin on
filetype indent on " file type based indentation
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType html setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType css setlocal shiftwidth=2 tabstop=2 expandtab
" remap F2 to nerdtreetoggle (thx brett)
nnoremap <F2> :NERDTreeToggle<cr>
" also map ctrl b (vscode)
nmap <C-B> :NERDTreeToggle <space>
" map ctrl f to fzf (finder)
nmap <C-F> :FZF<space>
" map ctrl s to find ocurrences
nmap <C-S> :Rg<space>
" Set textwidth at 100
set textwidth=100

augroup custom_filetypes
    au!
    au BufRead,BufNewFile *.jsx setlocal filetype=javascript
    au BufRead,BufNewFile *.jsonld setlocal filetype=json
    au BufRead,BufNewFile *.cshtml setlocal filetype=html
    au BufRead,BufNewFile *.cshtml_ setlocal filetype=html
    au BufRead,BufNewFile *.scss setlocal filetype=css
    au BufRead,BufNewFile *.md setlocal filetype=markdown
augroup END
