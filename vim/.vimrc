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
Plug 'tpope/vim-fugitive'
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
  \ 'coc-tsserver',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-json', 
  \ ]
" devtools / dev setup
Plug 'luochen1990/rainbow'
let g:rainbow_active = 1 " also :RainbowToggle
Plug 'APZelos/blamer.nvim'
let g:blamer_enabled = 1
let g:blamer_delay = 500
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
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
" colorschemes
Plug 'cormacrelf/vim-colors-github'
Plug 'Brettm12345/moonlight.vim'
Plug 'sheerun/vim-wombat-scheme'
Plug 'ntk148v/vim-horizon'
Plug 'herrbischoff/cobalt2.vim'
Plug 'morhetz/gruvbox'
Plug 'kaicataldo/material.vim'
Plug 'whatyouhide/vim-gotham'
Plug 'jeffkreeftmeijer/vim-dim'
" Plug 'chriskempson/base16-vim'
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

" :set guicursor=a:blinkon100

set number
set tabstop=2 " tab width = 4, (only interpretation)
set softtabstop=2 " useful for python, for example
set shiftwidth=2 " indents -> width 4
set expandtab "expand tab to space
set guifont=SF\ Mono\ Nerd\ Font:h14
set hlsearch
" set cursorline
" set autoread
" set mouse=i
syntax enable
if (has("nvim"))
  "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

" Enable 256 on neovim
if (has("termguicolors"))
  set termguicolors
endif
set termguicolors
colorscheme gruvbox 
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