local map = vim.keymap.set
map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
for key, direction in pairs { h = 'left', j = 'lower', k = 'upper', l = 'right' } do
  map('n', '<C-' .. key .. '>', '<C-w>' .. key, { desc = 'Focus ' .. direction .. ' window' })
end
map('n', '[d', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Previous diagnostic' })
map('n', ']d', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Next diagnostic' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Diagnostic details' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic list' })
