local function close_buffer(bufnr)
  -- Preserve the window layout and prompt before discarding unsaved changes.
  require('mini.bufremove').delete(bufnr, false)
end

return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<C-b>', '<cmd>Neotree filesystem reveal_force_cwd toggle<CR>', desc = 'Toggle file tree' },
      { '<C-b>', '<Esc><cmd>Neotree filesystem reveal_force_cwd toggle<CR>', mode = 'i', desc = 'Toggle file tree' },
      { '<leader>fb', '<cmd>Neotree filesystem reveal_force_cwd toggle<CR>', desc = 'File browser' },
      { '<leader>tt', '<cmd>Neotree filesystem reveal_force_cwd toggle<CR>', desc = '[T]oggle file [T]ree' },
      { '<leader>bb', '<cmd>Neotree buffers reveal_force_cwd<CR>', desc = 'Show open [B]uffers' },
      { '<leader>ge', '<cmd>Neotree git_status<CR>', desc = 'Show [G]it changes in [E]xplorer' },
    },
    -- Load at startup so `nvim .` opens the explorer too.
    lazy = false,
    init = function()
      -- Neo-tree clears this group even when netrw was disabled before startup.
      vim.api.nvim_create_augroup('FileExplorer', { clear = false })
    end,
    opts = {
      sources = { 'filesystem', 'buffers', 'git_status' },
      source_selector = { winbar = true, statusline = false },
      window = {
        width = 36,
        mappings = {
          ['l'] = 'open',
          ['h'] = 'close_node',
          ['<Right>'] = 'open',
          ['<Left>'] = 'close_node',
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = { hide_dotfiles = false, hide_gitignored = true },
      },
      buffers = { follow_current_file = { enabled = true } },
    },
  },
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '[b', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous buffer' },
      { ']b', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
      { '<leader>bp', '<cmd>BufferLinePick<CR>', desc = '[B]uffer [P]icker' },
      {
        '<leader>bd',
        function()
          close_buffer(0)
        end,
        desc = '[B]uffer [D]elete',
      },
    },
    lazy = false,
    opts = {
      options = {
        mode = 'buffers',
        diagnostics = 'nvim_lsp',
        separator_style = 'thin',
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        close_command = close_buffer,
        right_mouse_command = close_buffer,
        offsets = {
          { filetype = 'neo-tree', text = 'Explorer', text_align = 'left', separator = true },
        },
      },
    },
  },
}
