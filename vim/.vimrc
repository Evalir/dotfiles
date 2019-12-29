call plug#begin('~/.vim/plugged')
" vim plugs
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'jiangmiao/auto-pairs'
Plug 'scrooloose/nerdcommenter'
let g:NERDSpaceDelims=1 " always insert spaces after commenting
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'scrooloose/nerdtree'
autocmd vimenter * NERDTree
Plug 'liuchengxu/vista.vim'
Plug 'ryanoasis/vim-devicons'
let NERDTreeShowHidden=1
Plug 'neoclide/coc.nvim', {'branch': 'release'}
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-tsserver',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-json', 
  \ ]
" devtools / dev setup
Plug 'fatih/vim-go', { 'do': ':GopdateBinaries' }
Plug 'rust-lang/rust.vim'
Plug 'tomlion/vim-solidity'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html', 'solidity', 'php', 'swift', 'python', 'ruby'] }
Plug 'psf/black'
Plug 'dense-analysis/ale'
let g:ale_fix_on_save=1
Plug 'othree/yajs.vim'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
" colorschemes
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

set number
set tabstop=2
set softtabstop=2
set expandtab
set guifont=MesloLGS\ Nerd\ Font:h13
set hlsearch
syntax enable
" for vim 7
set t_Co=256
" for vim 8
 if (has("termguicolors"))
  set termguicolors
 endif

set termguicolors
colorscheme OceanicNext 
filetype plugin on
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType html setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType css setlocal shiftwidth=2 tabstop=2 expandtab
