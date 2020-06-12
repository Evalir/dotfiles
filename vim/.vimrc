call plug#begin('~/.vim/plugged')
" vim plugins
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme="deus"
Plug 'jiangmiao/auto-pairs'
Plug 'scrooloose/nerdcommenter'
let g:NERDSpaceDelims=1 " always insert spaces after commenting
Plug 'tpope/vim-fugitive'
Plug 'myusuf3/numbers.vim'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'scrooloose/nerdtree'
let NERDTreeShowHidden=1
Plug 'ntpeters/vim-better-whitespace'

" devtools / dev setup
Plug 'neoclide/coc.nvim', {'branch': 'release'}
let g:coc_global_extensions = [
  \ 'coc-tsserver'
  \ ]
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'luochen1990/rainbow'
let g:rainbow_active = 1 " also :RainbowToggle
Plug 'APZelos/blamer.nvim'
let g:blamer_enabled = 1
let g:blamer_delay = 1000
let g:blamer_show_in_visual_modes = 0
Plug 'sheerun/vim-polyglot'
Plug 'mustache/vim-mustache-handlebars'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'rust-lang/rust.vim'
Plug 'tomlion/vim-solidity'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html', 'solidity', 'php', 'swift', 'python'] }
Plug 'gorodinskiy/vim-coloresque'
Plug 'psf/black'
Plug 'pangloss/vim-javascript'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'mhartington/nvim-typescript', {'do': './install.sh'}
" For async completion
Plug 'Shougo/deoplete.nvim'
 " For Denite features
Plug 'Shougo/denite.nvim'
let g:deoplete#enable_at_startup = 1
Plug 'mxw/vim-jsx'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" colorschemes
Plug 'joshdick/onedark.vim'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'sainnhe/edge'
Plug 'chriskempson/base16-vim'
Plug 'rakr/vim-two-firewatch'
Plug 'cocopon/iceberg.vim'
Plug 'rakr/vim-one'
Plug 'chriskempson/base16-vim'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'haishanh/night-owl.vim'
Plug 'crusoexia/vim-monokai'
Plug 'mhartington/oceanic-next'
call plug#end()

"----- GENERAL CONFIG ------

set number
set tabstop=2 " tab width = 4, (only interpretation)
set softtabstop=2 " useful for python, for example
set shiftwidth=2 " indents -> width 4
set expandtab "expand tab to space
set hlsearch
set clipboard=unnamed
set mouse=a
" ignore case when typing
set ignorecase
" but, if we type a cap letter, don't
set smartcase
" Show invisibles
set list
set listchars=tab:¬ª-,trail:¬∑

"----- SYNTAX CONFIG ------

syntax enable
if (has("nvim"))
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

colorscheme one

filetype on
filetype plugin on
filetype indent on " file type based indentation

autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType html setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType css setlocal shiftwidth=2 tabstop=2 expandtab


"----- KEYBIND REMAP CONFIG ------


" remap F2 to nerdtreetoggle (thx brett)
nnoremap <F2> :NERDTreeToggle<cr>
" also map ctrl b (vscode)
nmap <C-B> :NERDTreeToggle <space><cr>
" map ctrl f to fzf (finder), respecting gitignore and making it fast af
nnoremap <expr> <C-f> (len(system('git rev-parse')) ? ':Files' : ':GFiles --exclude-standard --others --cached')."\<cr>"
" map ctrl s to find ocurrences (ripgrep)
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
