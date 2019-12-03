" enable line numbers
" gotta see them lines yo'
set number
" set dem 4 tabz
set tabstop=4
set softtabstop=4
" 1 TAB SAVES YOU 8 SPACES!!
" Yeah, not today. Spaces plz.
set expandtab
" cuz in js and html, 2 spaces yo'
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
autocmd FileType html       setlocal shiftwidth=2 tabstop=2

" dem plugins
call plug#begin('~/.vim/plugged')
" statusline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" gotta pretty up dem codez
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
" dem colors
Plug 'sjl/badwolf'
Plug 'haishanh/night-owl.vim'
Plug 'micha/vim-colors-solarized'
Plug 'crusoexia/vim-monokai'
Plug 'mhartington/oceanic-next'
Plug 'othree/yajs.vim'
Plug 'pangloss/vim-javascript'
" jsx / frontend setup stuff
Plug 'mxw/vim-jsx'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" python linter setup
Plug 'psf/black'
call plug#end()
" gotta see them colors
syntax enable
" for vim 7
 set t_Co=256

" for vim 8
 if (has("termguicolors"))
  set termguicolors
 endif

set termguicolors
colorscheme dim
