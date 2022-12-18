local function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Fast :nohls
map('', '<leader>no', ':nohls<cr>')

-- Close buffers easily by doing leader db
map('', '<leader>db', ':bd<cr>')

-- telescope bindings
map('', '<C-f>', '<cmd>Telescope find_files<cr>')
map('', '<C-g>', '<cmd>Telescope git_files<cr>')
map('', '<C-S>', ':<cmd>Telescope live_grep<cr><enter>')
map('', '<leader>tl', '<cmd>Telescope<cr>')
map('', '<leader>fb', '<cmd>Telescope file_browser<cr>')
map('', '<C-b>', ':<cmd>NvimTreeToggle<cr><enter>')
map('', '<leader>bf', '<cmd>Telescope buffers<cr>')
map('', '<leader>gc', '<cmd>Telescope git_commits<cr><enter>')
map('', '<leader>gb', '<cmd>Telescope git_branches<cr><enter>')

-- lightbulb
map('', '<leader>do', '<cmd>lua vim.lsp.buf.code_action() <CR>')

-- trouble
map('', '<leader>tr', ':Trouble<cr>')

-- Floaterm
map('', '<leader>ft', ':FloatermToggle<cr>')
