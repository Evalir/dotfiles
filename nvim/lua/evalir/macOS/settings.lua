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
opt.shiftwidth = 4
opt.smartcase = true
opt.smartindent = true
opt.softtabstop = 4
opt.tabstop = 4
opt.wrap = true

-- set to auto read when a file is changed from the outside
opt.autoread = true
-- no auto folding
opt.foldenable = false


vim.o.encoding = 'UTF-8'
vim.o.list = true
vim.o.showbreak = '↪'
vim.opt.listchars = {
  tab = '→ ',
  eol = '¬',
  nbsp = '␣',
  trail = '•',
  extends = '⟩',
  precedes = '⟨'
}

-- misc
-- set cursor to block on insert mode
vim.cmd([[ set guicursor=i:block ]])
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


-- jsdoc
vim.cmd([[let g:jsdoc_default_mapping = 0]])

-- vgit related
vim.o.updatetime = 300
vim.wo.signcolumn = 'yes'
