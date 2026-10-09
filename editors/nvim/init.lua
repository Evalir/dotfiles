-- Personal Neovim config. See README.md for requirements and shortcuts.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- All plugins use Lua/LSP; a Python remote-plugin host is unnecessary.
vim.g.loaded_python3_provider = 0
vim.g.loaded_python_provider = 0

if vim.fn.has 'nvim-0.12' == 0 then
  error 'This config requires Neovim 0.12+. See editors/nvim/README.md.'
end

require 'config.options'
require 'config.keymaps'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local result = vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  }
  if vim.v.shell_error ~= 0 then
    error('Could not install lazy.nvim:\n' .. result)
  end
end
vim.opt.rtp:prepend(lazypath)
require('lazy').setup('plugins', {
  change_detection = { notify = false },
})

-- The default theme; alternatives are listed in lua/plugins/themes.lua.
vim.cmd.colorscheme 'github_dark_high_contrast'
