-- Shared by interactive setup and the isolated dotfiles readiness helper.
return {
  parsers = {
    'bash', 'c', 'html', 'json', 'lua', 'markdown', 'markdown_inline',
    'python', 'rust', 'toml', 'vim', 'vimdoc', 'yaml',
  },
  tools = {
    ['rust-analyzer'] = 'rust-analyzer', pyright = 'pyright-langserver',
    ruff = 'ruff', ['lua-language-server'] = 'lua-language-server', stylua = 'stylua',
  },
}
