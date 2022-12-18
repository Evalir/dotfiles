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
