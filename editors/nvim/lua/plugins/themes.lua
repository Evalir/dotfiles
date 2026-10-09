-- Lazy loads a theme when :colorscheme selects it. No highlight overrides.
return {
  { 'projekt0n/github-nvim-theme', name = 'github-theme', lazy = true, opts = {} },
  { 'ellisonleao/gruvbox.nvim', lazy = true, opts = { contrast = 'hard' } },
  { 'loctvl842/monokai-pro.nvim', version = '1.*', lazy = true, opts = { filter = 'classic' } },
  { 'Mofiqul/dracula.nvim', lazy = true, opts = {} },
}
