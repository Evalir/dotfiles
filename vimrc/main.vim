set number
set tabstop=4 " tab width = 4, (only interpretation)
set softtabstop=4 " useful for python, for example
set shiftwidth=2 " indents -> width 4
set expandtab "expand tab to space
set hlsearch
" Copy and paste for vim in the same register of the whole computer
set clipboard=unnamed
set clipboard=unnamedplus
set mouse=a
" highlight line you're on
set cursorline
" ignore case when typing
set ignorecase
" but, if we type a cap letter, don't
set smartcase
" Set encoding format to a sensible default
set encoding=utf-8

" No auto folding
set nofoldenable

"----- SYNTAX CONFIG ------
set t_Co=256
if has("termguicolors")
  set termguicolors
endif
set termguicolors

lua << EOF
local base16 = require "base16"
base16(base16.themes["onedark"], true)
EOF

filetype on
filetype plugin on
filetype indent on " file type based indentation
autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear

augroup custom_filetypes
    au!
    au BufRead,BufNewFile *.jsx setlocal filetype=javascript
    au BufRead,BufNewFile *.jsonld setlocal filetype=json
    au BufRead,BufNewFile *.cshtml setlocal filetype=html
    au BufRead,BufNewFile *.cshtml_ setlocal filetype=html
    au BufRead,BufNewFile *.scss setlocal filetype=css
    au BufRead,BufNewFile *.md setlocal filetype=markdown
augroup END
