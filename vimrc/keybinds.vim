" Fast :nohls
nmap <leader>no :nohls<cr>
" Close buffers easil by doing leader db
nmap <leader>db :bd<cr>
" also map ctrl b (vscode)
nmap <C-B> :NERDTreeToggle <space><cr>
nmap <C-v> :NvimTreeToggle<CR>
" Git files preview
nmap <C-f> :CocCommand fzf-preview.GitFiles <space><cr>
" Visualize buffers with leader ( \ ) bf
nmap <leader>bf :CocCommand fzf-preview.Buffers<cr>
" Also see the branches for easy switching with leader b
nmap <leader>gs :FzfPreviewGitStatus<cr>
nmap <leader>ga :FzfPreviewGitActions<cr>
" map ctrl s to find ocurrences (ripgrep)
nmap <C-S> :Rg<space>
" map Rustfmt to <leader>rf
nmap <leader>rf :RustFmt<cr>
nmap <leader>ft :FloatermToggle<cr>
let g:rustfmt_autosave = 1
" Switch between tabs
nnoremap <C-k> :tabnext<cr>
nnoremap <C-j> :tabprev<cr>

let g:jsdoc_default_mapping = 0
noremap <Leader>j :JsDoc<cr>

set listchars=nbsp:·,tab:▸\ ,eol:¬
set list
