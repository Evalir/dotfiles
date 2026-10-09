return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install {
        'bash',
        'c',
        'html',
        'json',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'rust',
        'toml',
        'vim',
        'vimdoc',
        'yaml',
      }
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
        callback = function(event)
          -- Filetypes without an installed parser keep normal syntax highlighting.
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
}
