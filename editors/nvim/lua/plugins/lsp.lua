return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'saghen/blink.cmp',
      { 'mason-org/mason.nvim', opts = {} },
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        opts = {
          ensure_installed = { 'rust-analyzer', 'pyright', 'ruff', 'lua-language-server', 'stylua' },
          integrations = { ['mason-lspconfig'] = false, ['mason-null-ls'] = false, ['mason-nvim-dap'] = false },
        },
      },
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
      vim.lsp.config('rust_analyzer', {
        settings = {
          ['rust-analyzer'] = { cargo = { buildScripts = { enable = true } }, procMacro = { enable = true } },
        },
      })
      vim.lsp.config('pyright', {
        before_init = function(_, config)
          if config.settings.python.pythonPath then
            return
          end
          local environments = {}
          for _, env in ipairs { 'VIRTUAL_ENV', 'CONDA_PREFIX' } do
            if vim.env[env] then
              table.insert(environments, vim.env[env])
            end
          end
          if config.root_dir then
            table.insert(environments, config.root_dir .. '/.venv')
            table.insert(environments, config.root_dir .. '/venv')
          end
          for _, env in ipairs(environments) do
            local python = env .. (vim.fn.has 'win32' == 1 and '/Scripts/python.exe' or '/bin/python')
            if vim.fn.executable(python) == 1 then
              config.settings.python.pythonPath = python
              return
            end
          end
        end,
        settings = {
          pyright = { disableOrganizeImports = true },
          python = { analysis = { typeCheckingMode = 'basic' } },
        },
      })
      vim.lsp.config('ruff', {
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      })
      vim.lsp.config('lua_ls', { settings = { Lua = { completion = { callSnippet = 'Replace' } } } })
      vim.lsp.enable { 'rust_analyzer', 'pyright', 'ruff', 'lua_ls' }

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-keymaps', { clear = true }),
        callback = function(event)
          local function map(keys, action, desc)
            vim.keymap.set('n', keys, action, { buffer = event.buf, desc = desc })
          end
          local telescope = require 'telescope.builtin'
          map('gd', telescope.lsp_definitions, 'Go to definition')
          map('gr', telescope.lsp_references, 'Find references')
          map('gI', telescope.lsp_implementations, 'Go to implementation')
          map('<leader>D', telescope.lsp_type_definitions, 'Type definition')
          map('<leader>ds', telescope.lsp_document_symbols, 'Document symbols')
          map('<leader>ws', telescope.lsp_dynamic_workspace_symbols, 'Workspace symbols')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
          map('K', vim.lsp.buf.hover, 'Hover documentation')
          map('gD', vim.lsp.buf.declaration, 'Go to declaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method 'textDocument/inlayHint' then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          end
          if client and client:supports_method 'textDocument/documentHighlight' then
            local group = vim.api.nvim_create_augroup('lsp-highlight-' .. event.buf, { clear = true })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'LspDetach' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },
}
