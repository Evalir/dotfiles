return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  --telescope
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
  -- or                            , branch = '0.1.x',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  -- treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  use 'nvim-treesitter/playground'

  use 'jiangmiao/auto-pairs'
  use "norcalli/nvim.lua"
  use 'preservim/nerdcommenter'
  use "fladson/vim-kitty"

  -- status bar
  use {
    'hoob3rt/lualine.nvim',
    requires = {'kyazdani42/nvim-web-devicons', opt = true}
  }

  -- Floating terminal
  use 'voldikss/vim-floaterm'

  -- File finder
  use {
      'kyazdani42/nvim-tree.lua',
      requires = 'kyazdani42/nvim-web-devicons',
  }

  -- coloration
  use "projekt0n/github-nvim-theme"
  use 'shaunsingh/nord.nvim'
  use 'overcache/NeoSolarized'
  use { "ellisonleao/gruvbox.nvim" }
  use {'shaunsingh/oxocarbon.nvim', run = './install.sh'}
  use ('Tsuzat/NeoSolarized.nvim')
  vim.g.nord_italic = false

  -- sorting
  use 'christoomey/vim-sort-motion'

  -- use :WhichKey to check the bindings
  use { 'folke/which-key.nvim', cmd = { 'WhichKey' } }

  -- remove the swap file messages
  use 'gioele/vim-autoswap'

  -- completion
  use {
    'VonHeikemen/lsp-zero.nvim',
    requires = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-nvim-lua'},

      -- Snippets
      {'L3MON4D3/LuaSnip'},
      {'rafamadriz/friendly-snippets'},
    }
  }

  -- nice icons for completion
  use 'onsails/lspkind-nvim';

  -- on-screen progress for lsp actions
  use "j-hui/fidget.nvim"

  -- virtual git
  use {
    'tanvirtin/vgit.nvim',
    requires = {
      'nvim-lua/plenary.nvim'
    }
  }

  -- debugging
  use 'mfussenegger/nvim-dap'

   --rust specific
  --use 'simrat39/rust-tools.nvim'
   --go specific
 --use('crispgm/nvim-go')
 

  -- diagnostics
  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons"
  }
end)

