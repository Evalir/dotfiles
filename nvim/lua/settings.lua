local opt = vim.opt
-- mouse things
opt.cursorline = true
opt.modeline = false
opt.mouse = 'a'

-- live search / replace
opt.inccommand = 'nosplit'

-- 24 bits colors
opt.termguicolors = true

-- disable column
opt.colorcolumn = ''
-- split to the right / below
opt.splitbelow = true
opt.splitright = true

-- whitespace and other misc things that everyone sets
opt.autoindent = true
opt.backspace = { 'indent', 'eol', 'start' }
opt.clipboard = 'unnamedplus'
opt.encoding = 'utf-8'
opt.expandtab = true
opt.hlsearch = true
opt.ignorecase = true
opt.incsearch = true
opt.relativenumber = true
vim.cmd([[set nu rnu]])
opt.shiftwidth = 2
opt.smartcase = true
opt.smartindent = true
opt.softtabstop = 2
opt.tabstop = 2
opt.wrap = true

-- set to auto read when a file is changed from the outside
opt.autoread = true
-- no auto folding
opt.foldenable = false
  
-- misc
-- custom filetypes
vim.cmd([[
augroup custom_filetypes
    au!
    au BufRead,BufNewFile *.jsx setlocal filetype=javascript
    au BufRead,BufNewFile *.jsonld setlocal filetype=json
    au BufRead,BufNewFile *.cshtml setlocal filetype=html
    au BufRead,BufNewFile *.cshtml_ setlocal filetype=html
    au BufRead,BufNewFile *.scss setlocal filetype=css
    au BufRead,BufNewFile *.md setlocal filetype=markdown
augroup END

]])

-- go
vim.cmd([[
au FileType go set noexpandtab
au FileType go set shiftwidth=4
au FileType go set softtabstop=4
au FileType go set tabstop=4

let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1

let g:go_auto_sameids = 1

let g:go_fmt_command = "goimports"

au FileType go nmap <leader>gt :GoDeclsDir<cr>
]])

-- solidity
vim.cmd([[
au FileType solidity set noexpandtab
au FileType solidity set shiftwidth=4
au FileType solidity set softtabstop=4
au FileType solidity set tabstop=4
]])
-- rustfmt autosave
vim.cmd([[let g:rustfmt_autosave = 1]])

-- jsdoc
vim.cmd([[let g:jsdoc_default_mapping = 0]])
