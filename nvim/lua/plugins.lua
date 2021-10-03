return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  use 'karb94/neoscroll.nvim'
  -- status bar
  use {
    'itchyny/lightline.vim',
    config = function() vim.g.lightline = { colorscheme = 'one' } end
  }

 -- fancy bufferline
  use {
    'akinsho/bufferline.nvim', 
    requires = 'kyazdani42/nvim-web-devicons'
  }

  use 'voldikss/vim-floaterm'

  use {
      'kyazdani42/nvim-tree.lua',
      requires = 'kyazdani42/nvim-web-devicons',
      config = function() require'nvim-tree'.setup {} end
  }
  -- coloration
  -- use 'gruvbox-community/gruvbox'
  use 'norcalli/nvim-base16.lua'
  use 'monsonjeremy/onedark.nvim'
  use {
    'eddyekofo94/gruvbox-flat.nvim',
    config = function()
      vim.g.gruvbox_transparent = true
      vim.g.gruvbox_flat_style = "hard"
    end
  }
  use 'norcalli/nvim-colorizer.lua'
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = { enable = true },
        indent = { enable = true }
      }
    end
  }
  --
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

  -- telescope
  use {
    'nvim-telescope/telescope.nvim',
    cmd = { "Telescope" },
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('telescope').setup {
        layout_strategy = 'center',
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = false, -- override the generic sorter
            override_file_sorter = true -- override the file sorter
          }
        },
        defaults = {
          -- Lua regex patterns: http://www.lua.org/pil/20.2.html
          -- "pkg/demo",
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

  -- languages
  use { 'rust-lang/rust.vim', ft = { 'rust' } }
  use { 'tomlion/vim-solidity', ft = { 'solidity' } }
  use { 'zah/nim.vim', ft = { 'nim' } }
  use { 'tikhomirov/vim-glsl', ft = { 'glsl' } }
  use {
    'plasticboy/vim-markdown',
    ft = { 'markdown' },
    config = function()
      vim.g.vim_markdown_fenced_languages = {
        'jsx=javascript', 'ts=typescript', 'tsx=typescript'
      }
    end
  }
    -- JS
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
