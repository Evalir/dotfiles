local function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Fast :nohls
map('', '<leader>no', ':nohls<cr>')

-- Close buffers easil by doing leader db
map('', '<leader>db', ':bd<cr>')

-- telescope bindings
map('', '<C-f>', '<cmd>Telescope find_files<cr>')
map('', '<C-g>', '<cmd>Telescope git_files<cr>')
map('', '<C-S>', ':<cmd>Telescope live_grep<cr>')
map('', '<C-b>', ':<cmd>NvimTreeToggle<cr><enter>')
map('', '<leader>bf', '<cmd>Telescope buffers<cr>')
map('', '<leader>gc', '<cmd>Telescope git_commits<cr><enter>')
map('', '<leader>gb', '<cmd>Telescope git_branches<cr><enter>')

-- Coc
map('', '<Leader>l', ':CocCommand explorer<CR>')

-- Formatting
map('', '<leader>p', ':CocCommand prettier.formatFile<CR>')

-- Rust things
-- AUTOSAVE
vim.g['rustfmt_autosave'] = 1
map('', '<leader>rf', ':RustFmt<cr>')


-- Floaterm
map('', '<leader>ft', ':FloatermToggle<cr>')

-- Tab switching
map('', '<C-k>', ':tabnext<cr>')
map('', '<C-j>', ':tabprev<cr>')

-- JsDoc
vim.g['jsdoc_default_mapping'] = 0
map('', '<leader>j', ':JsDoc<cr>')
