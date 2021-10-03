vim.cmd([[
let g:lightline = {
      \ 'colorscheme': 'one',
      \ }
]])
-- following options are the default
require'nvim-tree'.setup {
  -- disables netrw completely
  disable_netrw       = true,
  -- hijack netrw window on startup
  hijack_netrw        = true,
  -- open the tree when running this setup function
  open_on_setup       = false,
  -- will not open on setup if the filetype is in this list
  ignore_ft_on_setup  = {},
  -- closes neovim automatically when the tree is the last **WINDOW** in the view
  auto_close          = false,
  -- opens the tree when changing/opening a new tab if the tree wasn't previously opened
  open_on_tab         = false,
  -- hijacks new directory buffers when they are opened.
  update_to_buf_dir   = {
    -- enable the feature
    enable = true,
    -- allow to open the tree if it was previously closed
    auto_open = true,
  },
  -- hijack the cursor in the tree to put it at the start of the filename
  hijack_cursor       = false,
  -- updates the root directory of the tree on `DirChanged` (when your run `:cd` usually) 
  update_cwd          = false,
  -- show lsp diagnostics in the signcolumn
  lsp_diagnostics     = false,
  -- update the focused file on `BufEnter`, un-collapses the folders recursively until it finds the file
  update_focused_file = {
    -- enables the feature
    enable      = false,
    -- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory
    -- only relevant when `update_focused_file.enable` is true
    update_cwd  = false,
    -- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory
    -- only relevant when `update_focused_file.update_cwd` is true and `update_focused_file.enable` is true
    ignore_list = {}
  },
  -- configuration options for the system open command (`s` in the tree by default)
  system_open = {
    -- the command to run this, leaving nil should work in most cases
    cmd  = nil,
    -- the command arguments as a list
    args = {}
  },

  view = {
    -- width of the window, can be either a number (columns) or a string in `%`
    width = 30,
    -- side of the tree, can be one of 'left' | 'right' | 'top' | 'bottom'
    side = 'left',
    -- if true the tree will resize itself after opening a file
    auto_resize = false,
    mappings = {
      -- custom only false will merge the list with the default mappings
      -- if true, it will only use your list to set the mappings
      custom_only = false,
      -- list of mappings to set on the tree manually
      list = {}
    }
  }
}

require('neoscroll').setup({
  mappings = {'<C-u>', '<C-d>'},
})

local t = {}
-- Syntax: t[keys] = {function, {function arguments}}
t['<C-u>'] = {'scroll', {'-vim.wo.scroll', 'true', '50'}}
t['<C-d>'] = {'scroll', { 'vim.wo.scroll', 'true', '50'}}

require('neoscroll.config').set_mappings(t)

require('bufferline').setup{
  options = {
  offsets = { { filetype = "NvimTree", text = "File Explorer", padding = 1 } },
  buffer_close_icon = "",
  modified_icon = "",
  -- close_icon = "%@NvChad_bufferline_quitvim@%X",
  close_icon = "",
  show_close_icon = true,
  left_trunc_marker = "",
  right_trunc_marker = "",
  max_name_length = 14,
  max_prefix_length = 13,
  tab_size = 20,
  show_tab_indicators = true,
  enforce_regular_tabs = false,
  view = "multiwindow",
  show_buffer_close_icons = true,
  show_buffer_icons = true,
  separator_style = "slant",
  always_show_bufferline = true,
  diagnostics = "coc",
  diagnostics_indicator = function(count, level, diagnostics_dict, context)
  local s = " "
  for e, n in pairs(diagnostics_dict) do
    local sym = e == "error" and " "
      or (e == "warning" and " " or "" )
    s = s .. n .. sym
  end
  return s
  end,
  custom_filter = function(buf_number)
     -- Func to filter out our managed/persistent split terms
     local present_type, type = pcall(function()
        return vim.api.nvim_buf_get_var(buf_number, "term_type")
     end)

     if present_type then
        if type == "vert" then
           return false
        elseif type == "hori" then
           return false
        else
           return true
        end
     else
        return true
     end
  end,
  }
}

require('colorizer').setup{
  '*';
}
