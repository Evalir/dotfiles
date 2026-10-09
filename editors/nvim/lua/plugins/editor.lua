return {
  'tpope/vim-sleuth',
  { 'github/copilot.vim', event = 'InsertEnter', cmd = 'Copilot' },
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      spec = {
        { '<leader>b', group = 'Buffers' },
        { '<leader>c', group = 'Code' },
        { '<leader>d', group = 'Document' },
        { '<leader>f', group = 'Files' },
        { '<leader>g', group = 'Git' },
        { '<leader>r', group = 'Rename' },
        { '<leader>s', group = 'Search' },
        { '<leader>t', group = 'Toggle' },
        { '<leader>w', group = 'Workspace' },
      },
    },
  },
  { 'folke/todo-comments.nvim', event = 'VeryLazy', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      require('mini.statusline').setup { use_icons = vim.g.have_nerd_font }
      require('mini.statusline').section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
  -- Keep the existing personal notes workflows; load only when needed.
  {
    'nvim-orgmode/orgmode',
    ft = 'org',
    cmd = 'Org',
    opts = { org_agenda_files = '~/orgfiles/**/*', org_default_notes_file = '~/orgfiles/refile.org' },
  },
  {
    'xolox/vim-notes',
    dependencies = { 'xolox/vim-misc' },
    event = 'VeryLazy',
    init = function()
      vim.g.notes_directory = '~/evalir/notes'
      vim.g.notes_suffix = '.md'
      vim.g.notes_date_format = '%Y-%m-%d %H:%M:%S'
    end,
  },
}
