local function picker(name, opts)
  return function()
    require('telescope.builtin')[name](opts)
  end
end

return {
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = vim.fn.executable 'make' == 1 },
      'nvim-telescope/telescope-ui-select.nvim',
    },
    keys = {
      { '<C-f>', '<cmd>Telescope find_files<CR>', desc = 'Find files' },
      { '<C-f>', '<Esc><cmd>Telescope find_files<CR>', mode = 'i', desc = 'Find files' },
      { '<leader>ff', picker 'find_files', desc = 'Find files' },
      { '<leader>fg', picker 'live_grep', desc = 'Search text' },
      {
        '<leader><leader>',
        picker('buffers', { sort_mru = true, ignore_current_buffer = true }),
        desc = 'Open buffers',
      },
      { '<leader>sh', picker 'help_tags', desc = 'Search help' },
      { '<leader>sk', picker 'keymaps', desc = 'Search keymaps' },
      { '<leader>sf', picker 'find_files', desc = 'Search files' },
      { '<leader>ss', picker 'builtin', desc = 'Search pickers' },
      { '<leader>sw', picker 'grep_string', desc = 'Search current word' },
      { '<leader>sg', picker 'live_grep', desc = 'Search text' },
      { '<leader>sd', picker 'diagnostics', desc = 'Search diagnostics' },
      { '<leader>sr', picker 'resume', desc = 'Resume search' },
      {
        '<leader>st',
        picker('colorscheme', {
          enable_preview = true,
          ignore_builtins = true,
          colors = {
            'github_dark_high_contrast',
            'github_dark_default',
            'github_dark_dimmed',
            'gruvbox',
            'monokai-pro-classic',
            'dracula',
          },
        }),
        desc = 'Preview themes',
      },
      { '<leader>s.', picker 'oldfiles', desc = 'Recent files' },
      { '<leader>s/', picker('live_grep', { grep_open_files = true }), desc = 'Search open files' },
      { '<leader>sn', picker('find_files', { cwd = vim.fn.stdpath 'config' }), desc = 'Search Neovim config' },
      { '<leader>/', picker 'current_buffer_fuzzy_find', desc = 'Search current buffer' },
    },
    config = function()
      local telescope = require 'telescope'
      telescope.setup {
        defaults = { sorting_strategy = 'ascending', layout_config = { prompt_position = 'top' } },
        pickers = { find_files = { hidden = true, file_ignore_patterns = { '^%.git/' } } },
        extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
      }
      pcall(telescope.load_extension, 'fzf')
      telescope.load_extension 'ui-select'
    end,
  },
}
