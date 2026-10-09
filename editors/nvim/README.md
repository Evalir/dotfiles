# Neovim config

This directory is linked to `~/.config/nvim` by `just link` in the dotfiles
root. Restart Neovim after editing the config. Plugin versions are recorded in
`lazy-lock.json`; use `:Lazy restore` to restore them.

## Everyday shortcuts

The leader key is **Space**.

| Shortcut | Action |
| --- | --- |
| `Ctrl-B` | Toggle the file tree and reveal the current file (normal/insert mode) |
| `Ctrl-F` | Fuzzy-find a file, including dotfiles (normal/insert mode) |
| `Space fg` | Search text across files |
| `Space Space` | Switch between open buffers |
| `Space bb` | Show open buffers in Neo-tree |
| `[b` / `]b` | Previous / next buffer tab |
| `Space bp` / `Space bd` | Pick a buffer tab / close the current buffer |
| `Space ge` | Show Git changes in Neo-tree |
| `Space st` | Live theme preview (Enter selects; Esc cancels) |
| `gd` / `gr` | Go to definition / find references |
| `K` | Show documentation under the cursor |
| `Space rn` / `Space ca` | Rename symbol / code action |
| `[d` / `]d` | Previous / next diagnostic |
| `Ctrl-Space` / `Ctrl-Y` | Trigger / accept completion |
| `Ctrl-U` / `Ctrl-D` | Scroll completion documentation |

Neo-tree has clickable Files, Buffers, and Git sources above the tree. Use
arrows or `hjkl` to navigate, Enter to open, `a` to create, `r` to rename,
`d` to delete (with confirmation), and `?` for help. `H` toggles hidden/ignored
files. Bufferline shows open files across the top, with icons, unsaved-change
markers, and diagnostics. Click to switch; click the close icon to close a
buffer (unsaved changes require confirmation). In file search, type part of a
filename, use arrows or
`Ctrl-N`/`Ctrl-P` to select, and Enter to open.

Tmux uses `Ctrl-B` as its default prefix: press it **twice** to send it to Neovim.

## Rust and Python

Mason installs **rust-analyzer**, **Pyright**, **Ruff**, and **LuaLS** automatically.
Run `:MasonToolsInstallSync` to finish installation explicitly. `:checkhealth vim.lsp`
shows attached servers; `:ConformInfo` shows available formatters.

- Rust: completion, navigation, diagnostics, inlay hints, and rustfmt on save.
  Install the toolchain components with `rustup component add rust-src rustfmt`.
- Python: Pyright handles types/completion/navigation; Ruff handles lint and
  code actions, with Ruff formatting on save. The interpreter comes from an
  activated virtualenv/Conda environment, then project `.venv` or `venv`, then
  Pyright's default discovery. Restart Neovim after changing environments, or
  use `:LspPyrightSetPythonPath /path/to/python`.
- Python remote plugins are disabled; this config uses Lua plugins and LSP,
  so editing Python does not require `pynvim`.

Formatting on save uses the file's directory to discover project rules:
`rustfmt.toml` / `.rustfmt.toml` and Cargo's edition for Rust,
`pyproject.toml` / `ruff.toml` / `.ruff.toml` for Python, and
`stylua.toml` / `.stylua.toml` for Lua. Rustup also selects the project's
toolchain. Python prefers Ruff installed in the project's `.venv` or `venv`,
falling back to Mason's Ruff. Formatter defaults apply when no config exists;
this does not automatically select other tools such as Black from project scripts.

Requires **Neovim 0.12+**, **tree-sitter CLI 0.26.1+**, a current Node.js for
Pyright/Copilot, Python 3, Rust, `git`, `make`, a C compiler, `curl`, `tar`,
`unzip`, and `ripgrep`. Icons need a Nerd Font in your terminal.

On macOS: `brew install neovim tree-sitter-cli ripgrep fd`. On other machines,
check `nvim --version` before linking; older distro packages may need upgrading.
Treesitter installs parsers on first launch. Restart after the initial install.
Use `:TSUpdate` after updating the plugin.

## Config layout

| File under `lua/` | Responsibility |
| --- | --- |
| `config/options.lua` | Editor options, diagnostics, yank highlighting |
| `config/keymaps.lua` | Basic navigation and diagnostics |
| `plugins/navigation.lua` | Neo-tree, Bufferline, safe buffer closing |
| `plugins/search.lua` | Telescope and search shortcuts |
| `plugins/completion.lua` | Stable Blink, native snippets, Lua API completion |
| `plugins/lsp.lua` | Native LSP setup and Mason tool installation |
| `plugins/formatting.lua` | Conform and project formatter discovery |
| `plugins/treesitter.lua` | Current Treesitter installer and native highlighting |
| `plugins/editor.lua` | Git signs, statusline, Copilot, personal notes |
| `plugins/themes.lua` | GitHub and three classic dark themes, loaded on demand |

Add plugin specs under `lua/plugins/`; Lazy imports that directory automatically.
Neovim handles commenting (`gcc` / `gc`) and `.editorconfig` natively. Blink
provides completion and signature help; `Ctrl-L`/`Ctrl-H` move through snippets,
while Tab remains available for Copilot.
Org files remain in `~/orgfiles`; Markdown notes remain in `~/evalir/notes`.

Maintenance: `:Lazy update` updates plugins and the lockfile; `:Lazy restore`
returns to the lockfile versions. Use `:Mason` for language tool updates,
`:checkhealth` for troubleshooting, and `:ConformInfo` for formatter selection.
The old Kickstart examples, unused themes, nvim-cmp/LuaSnip stack, Comment.nvim,
and mason-lspconfig bridge have been removed.

## Themes

The default is **GitHub Dark High Contrast**, with a near-black background.
Base16 and the old theme collection have been
removed from the config and lockfile. Themes load on demand, without custom
highlight overrides. `Space st` previews them live; Enter keeps the selection
for this session, and Esc restores the previous theme. To change the startup
default, edit the single `vim.cmd.colorscheme` line at the end of `init.lua`.

| Theme command | Style | Upstream screenshot |
| --- | --- | --- |
| `:colorscheme github_dark_high_contrast` | Near-black background, bright GitHub colors | [GitHub theme previews](https://github.com/projekt0n/github-nvim-theme#screenshots) |
| `:colorscheme github_dark_default` | Standard GitHub dark palette | [GitHub theme previews](https://github.com/projekt0n/github-nvim-theme#screenshots) |
| `:colorscheme github_dark_dimmed` | Softer GitHub dark palette | [GitHub theme previews](https://github.com/projekt0n/github-nvim-theme#screenshots) |
| `:colorscheme gruvbox` | Hard dark background, warm yellow/orange/green | [Gruvbox dark/light comparison](https://i.postimg.cc/fy3tnGFt/gruvbox-themes.png) |
| `:colorscheme monokai-pro-classic` | Classic Monokai: vivid pink, lime, cyan on charcoal | [Monokai Classic](https://user-images.githubusercontent.com/80513079/209659153-9362a05f-2b7f-4b36-acf1-d13bef6a9118.png) |
| `:colorscheme dracula` | Classic purple, pink, cyan and bright green | [Dracula](https://raw.githubusercontent.com/Mofiqul/dracula.nvim/main/assets/showcase.png) |

Monokai uses the stable v1 release series. If an older Packer installation exists
under `~/.local/share/nvim/site/pack/packer`, move it outside `site/pack` before
starting this config; its old plugins and themes can shadow Lazy's versions.

References: [Blink stable](https://cmp.saghen.dev/),
[Neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim),
[Bufferline](https://github.com/akinsho/bufferline.nvim),
[Treesitter](https://github.com/nvim-treesitter/nvim-treesitter),
[Ruff configuration](https://docs.astral.sh/ruff/configuration/).
