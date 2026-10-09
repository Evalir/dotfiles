return {
  {
    'stevearc/conform.nvim',
    opts = function()
      local util = require 'conform.util'
      local python_bin = vim.fn.has 'win32' == 1 and 'Scripts/ruff.exe' or 'bin/ruff'
      return {
        notify_on_error = true,
        format_on_save = function(bufnr)
          -- Prefer the configured formatter; fall back to LSP for other languages.
          local disable_filetypes = { c = true, cpp = true }
          return {
            timeout_ms = 2000,
            lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback',
          }
        end,
        formatters_by_ft = {
          lua = { 'stylua' },
          python = { 'ruff_format' },
          rust = { 'rustfmt' },
        },
        -- Run from the file's directory so toolchains and config discovery are
        -- tied to that project, even when Neovim was launched somewhere else.
        -- Keep Conform's stdin filename/ignore flags and Rust edition detection.
        formatters = {
          rustfmt = {
            cwd = function(_, ctx)
              return ctx.dirname
            end,
          },
          ruff_format = {
            command = util.find_executable({ '.venv/' .. python_bin, 'venv/' .. python_bin }, 'ruff'),
            cwd = function(_, ctx)
              return ctx.dirname
            end,
          },
          stylua = {
            cwd = function(_, ctx)
              return ctx.dirname
            end,
          },
        },
      }
    end,
  },
}
