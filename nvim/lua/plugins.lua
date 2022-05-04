function reapply_colorscheme()
  vim.cmd('colorscheme ' .. vim.api.nvim_exec('colorscheme', true))
end

return require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  use 'tomlion/vim-solidity'
  use 'jiangmiao/auto-pairs'
  use 'tpope/vim-surround'
  use "norcalli/nvim.lua"
  use 'preservim/nerdcommenter'
  use 'karb94/neoscroll.nvim'
  -- status bar
  use {
    'hoob3rt/lualine.nvim',
    requires = {'kyazdani42/nvim-web-devicons', opt = true}
  }

  use 'voldikss/vim-floaterm'
  use { "Lunarvim/Onedarker" }

  -- commenting
  use {'winston0410/commented.nvim'}

  use {
      'kyazdani42/nvim-tree.lua',
      requires = 'kyazdani42/nvim-web-devicons',
      config = function() require'nvim-tree'.setup {} end
  }
  -- coloration
  use 'ishan9299/nvim-solarized-lua'
  use 'liuchengxu/space-vim-dark'
  use 'monsonjeremy/onedark.nvim'
  use 'morhetz/gruvbox'
  use 'norcalli/nvim-colorizer.lua'
  use 'sainnhe/gruvbox-material'
  use "projekt0n/github-nvim-theme"
  -- treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        -- A list of parser names, or "all"
        ensure_installed = { "c", "lua", "rust" },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- List of parsers to ignore installing (for "all")
        ignore_install = { "javascript" },

        highlight = {
          -- `false` will disable the whole extension
          enable = true,

          -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
          -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
          -- the name of the parser)
          -- list of language that will be disabled
          disable = { "c", "rust" },

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
      }
    end
  }

  -- start screen
  use {
    'mhinz/vim-startify',
    config = function()

      -- start startify lists at 1
      vim.g.startify_custom_indices = vim.fn.map(vim.fn.range(1, 100),
                                                 'string(v:val)')
      vim.g.startify_custom_header = {}
      -- faster (but might miss some files)
      vim.g.startify_enable_unsafe = 1
      vim.g.startify_change_to_vcs_root = 0
      vim.g.startify_change_to_dir = 1
    end
  }

    -- adjusts 'shiftwidth' and 'expandtab' heuristically
  use 'tpope/vim-sleuth'

   --telescope
  use {
    'nvim-telescope/telescope.nvim',
    cmd = { "Telescope" },
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('telescope').setup {
        layout_strategy = 'center',
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = false,
            override_file_sorter = true
          }
        },
        defaults = {
           "pkg/demo",
          file_ignore_patterns = {
            "pkg/kit%-legacy", "pkg/website", "node_modules", "**/*.png",
            "**/*.jpg", "**/*.gif", "**/*.woff2", "**/*.mp4"
          }
        }
      }
    end
  }

  -- prettier etc.
  use {
    'mhartington/formatter.nvim',
    config = function()
      local prettier = {
        function()
          return {
            exe = "prettier",
            args = {
              "--stdin-filepath", '"' .. vim.api.nvim_buf_get_name(0) .. '"'
            },
            stdin = true
          }
        end
      }
      local luaFmt = {
        function()
          return {
            exe = "lua-format",
            args = {
              "--indent-width=2 --spaces-inside-table-braces --break-after-operator"
            },
            stdin = true
          }
        end
      }
      require('formatter').setup {
        logging = false,
        filetype = {
          html = prettier,
          markdown = prettier,
          json = prettier,
          typescript = prettier,
          typescriptreact = prettier,
          javascriptreact = prettier,
          javascript = prettier,
          solidity = prettier,
          lua = luaFmt
        }
      }
    end
  }

  -- sorting, super useful
  use 'christoomey/vim-sort-motion'

  -- use :WhichKey to check the bindings
  use { 'folke/which-key.nvim', cmd = { 'WhichKey' } }

  -- remove the swap file messages
  use 'gioele/vim-autoswap'

  -- everything completion
  use { 'neoclide/coc.nvim', branch = 'release' }

  -- git
  use 'tpope/vim-fugitive'
  use 'airblade/vim-gitgutter'
  use 'tpope/vim-rhubarb'

  -- debugging
  use 'mfussenegger/nvim-dap'

  -- languages
  -- rust
  use 'simrat39/rust-tools.nvim'

  -- md
  use {
    'plasticboy/vim-markdown',
    ft = { 'markdown' },
    config = function()
      vim.g.vim_markdown_fenced_languages = {
        'jsx=javascript', 'ts=typescript', 'tsx=typescript'
      }
    end
  }
  -- hcl
  use 'jvirtanen/vim-hcl'

  -- go
  -- CoC doesn't play nice with it, it seems
  use 'fatih/vim-go'

    -- js
  local jsts = {
    'javascript', 'javascriptreact', 'typescript', 'typescriptreact'
  }
  use { 'jparise/vim-graphql', ft = vim.list_extend(jsts, { 'graphql' }) }
  use { 'heavenshell/vim-jsdoc', ft = jsts }
  use { 'jxnblk/vim-mdx-js', ft = jsts }
  use { 'moll/vim-node', ft = jsts }
  use { 'posva/vim-vue', ft = { 'vue' } }
  use { 'evanleck/vim-svelte', branch = 'main', ft = { 'svelte' } }
end)
