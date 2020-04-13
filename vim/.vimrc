call plug#begin('~/.vim/plugged')
" vim plugins
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
Plug 'myusuf3/numbers.vim'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'jremmen/vim-ripgrep'
Plug 'scrooloose/nerdtree'
let NERDTreeShowHidden=1
Plug 'liuchengxu/vista.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'ntpeters/vim-better-whitespace'
" scratchpad
Plug 'metakirby5/codi.vim'
let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-tsserver',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-json',
  \ ]
" devtools / dev setup
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'luochen1990/rainbow'

Plug 'vim-syntastic/syntastic'

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1


let g:rainbow_active = 1 " also :RainbowToggle
Plug 'APZelos/blamer.nvim'
let g:blamer_enabled = 1
let g:blamer_delay = 500
Plug 'mustache/vim-mustache-handlebars'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'rust-lang/rust.vim'
Plug 'tomlion/vim-solidity'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html', 'solidity', 'php', 'swift', 'python'] }
Plug 'gorodinskiy/vim-coloresque'
Plug 'psf/black'
Plug 'dense-analysis/ale'
let g:ale_linters = {'ruby': ['rubocop']}
let g:ale_fixers = {'ruby': ['rubocop'], '*': ['remove_trailing_lines', 'trim_whitespace']}
let g:ale_fix_on_save = 1
let g:ruby_indent_assignment_style = 'variable'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
" colorschemes
Plug 'Nequo/vim-allomancer'
Plug 'https://gitlab.com/protesilaos/tempus-themes-vim.git'
Plug 'victorze/foo'
Plug 'arcticicestudio/nord-vim'
Plug 'chriskempson/base16-vim'
Plug 'rakr/vim-two-firewatch'
Plug 'vim-scripts/Zenburn'
Plug 'arzg/vim-colors-xcode'
Plug 'ayu-theme/ayu-vim'
Plug 'rakr/vim-one'
Plug 'mhartington/oceanic-next'
Plug 'cormacrelf/vim-colors-github'
Plug 'Brettm12345/moonlight.vim'
Plug 'sheerun/vim-wombat-scheme'
Plug 'ntk148v/vim-horizon'
Plug 'herrbischoff/cobalt2.vim'
Plug 'morhetz/gruvbox'
Plug 'kaicataldo/material.vim'
Plug 'whatyouhide/vim-gotham'
Plug 'jeffkreeftmeijer/vim-dim'
Plug 'chriskempson/base16-vim'
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
set clipboard=unnamed
set mouse=a
" set cursorline
" set autoread
" set mouse=i
syntax enable
if (has("nvim"))
  "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

"For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
"Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
" < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
colorscheme nord
" Different colorscheme for solidity & python
" autocmd FileType solidity colorscheme two-firewatch
" autocmd FileType javascript colorscheme xcodewwdc
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
