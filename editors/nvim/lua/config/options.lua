local options = {
  number = true,
  relativenumber = true,
  mouse = 'a',
  showmode = false,
  termguicolors = true,
  background = 'dark',
  breakindent = true,
  undofile = true,
  ignorecase = true,
  smartcase = true,
  signcolumn = 'yes',
  updatetime = 250,
  timeoutlen = 300,
  splitright = true,
  splitbelow = true,
  list = true,
  listchars = { tab = '» ', trail = '·', nbsp = '␣' },
  inccommand = 'split',
  cursorline = true,
  scrolloff = 10,
  confirm = true,
}
for name, value in pairs(options) do
  vim.opt[name] = value
end
-- Defer clipboard detection until after startup. EditorConfig is built in.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.diagnostic.config { severity_sort = true, underline = true, virtual_text = true, float = { border = 'rounded' } }
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
