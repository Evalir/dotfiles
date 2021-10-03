vim.cmd([[ source ~/.config/nvim/coc.vim ]])
require('settings')
require('plugins')
require('pluginconfig')
require('fzf')
require('keybinds')

-- Colors!
require('onedark').setup()
