# Carlos's Neovim config

Migrated from the January 2025 config to [Kickstart](https://github.com/nvim-lua/kickstart.nvim) commit `80743df53d8f7058fc5b60e41f1081d11df9c880`, dated September 14, 2026.

Requires **Neovim 0.12 or newer**. Plugins use Neovim's built-in `vim.pack` manager. Personal plugins and compatibility mappings live in `lua/custom/personal.lua`; the rest of `init.lua` follows the current Kickstart structure. Supermaven and VimTeX have been removed as requested.

## Try it separately

Keep your existing config while trying this one. From this repository's root:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
ln -s "$PWD" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim-migrated"
NVIM_APPNAME=nvim-migrated nvim
```

Choose an unused app name if `nvim-migrated` already exists. `NVIM_APPNAME` also isolates plugins, cache, and state. First startup downloads plugins, Mason tools, and Tree-sitter parsers. Reopen a file after the initial installs finish if its LSP or formatter is not yet available.

Install `git`, `make`, a C compiler, `unzip`, `curl`, `ripgrep`, `fd`, and the [Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/tree/master/crates/cli) 0.26.1 or newer, installed through a system package manager or an official release binary. Node.js/npm supports the JavaScript formatters and Markdown linter; Python with pip/venv supports Black; LuaLS and StyLua are downloaded by Mason. Set `vim.g.have_nerd_font = false` in `init.lua` if your terminal font does not support icons. Clipboard integration needs your platform's clipboard provider.

Gleam is configured with `vim.lsp.config` and `vim.lsp.enable`. Install [Gleam](https://gleam.run/getting-started/installing/) separately and put `gleam` on PATH. Its executable includes the language server. LuaLS remains the other enabled language server; add other servers to the `servers` table and their Mason packages to `ensure_installed` as needed.

## Shortcuts

Leader and local leader are both Space.

| Keys | Action |
| --- | --- |
| `H`, `L` | Previous / next buffer |
| `D` | Delete current buffer, preserving windows; prompt for unsaved edits |
| `Ctrl-h/j/k/l` in normal mode | Navigate splits |
| `Space .` | mini.files explorer |
| `Space Space` | Buffer picker |
| `Space sf`, `sg`, `sw`, `s.` | Find files, live grep, word search, recent files |
| `Space /`, `s/`, `sn` | Search current buffer, open files, config |
| `Space f` | Format buffer or visual selection |
| `gd`, `gr`, `gI`, `gD` | Definition, references, implementation, declaration |
| `Space D`, `ds`, `ws` | Type definition, document symbols, workspace symbols |
| `Space rn`, `ca`, `th` | Rename, code action, toggle inlay hints if supported |
| `Space xx`, `xX` | Trouble diagnostics, all buffers / current buffer |
| `Space cs`, `cl`, `xL`, `xQ` | Trouble symbols, LSP, location list, quickfix |
| `Ctrl-n/p`, `Ctrl-y`, `Ctrl-Space` in insert mode | Completion next/previous, accept, show |
| `Ctrl-b/f` in insert mode | Scroll completion documentation |
| `Ctrl-l/h`, `Tab/Shift-Tab` in snippets | Next / previous snippet stop |
| `Esc Esc` in terminal mode | Return to normal mode |

Current Kickstart's `grd`, `grr`, `gri`, `grt`, `grn`, `gra`, `grD`, `gO`, and `gW` mappings also work. The old `gr` mapping waits up to `timeoutlen` for another key so both families can coexist. Run `Space sk` to inspect mappings, or pause after Space for which-key.

## Changes

- `lazy.nvim` becomes native `vim.pack`; track `nvim-pack-lock.json` for reproducible plugin revisions.
- `nvim-cmp` becomes Blink with LuaSnip. Completion uses Blink's Lua matcher, without a Rust binary download.
- `vim-sleuth` becomes guess-indent. Mini icons replaces the separate web-devicons plugin.
- `mini.files`, `mini.pairs`, and `mini.tabline` remain. `mini.bufremove` replaces Snacks, which was only used for buffer deletion.
- Trouble stays. Supermaven and VimTeX are removed, including their shortcuts and engine settings.
- Gleam and Markdown linting are now loaded. Their previous `lua/plugins` modules were never imported by `lazy.setup`.
- Treesitter uses the current `main` branch API and native highlighting. It installs parsers as filetypes are opened.
- Formatting on save remains enabled. Lua uses StyLua, Python uses Black, and JavaScript/TypeScript uses prettierd or Prettier. The old Python formatter value was a string where Conform expects a list; this is fixed. C/C++ still avoid LSP formatting on save.

## Maintenance

Inspect plugin updates with `:lua vim.pack.update(nil, { offline = true })`. Fetch updates with `:lua vim.pack.update()`, then `:write` to apply or `:quit` to cancel. Commit the resulting lockfile. Use `:Mason` for tools, `:ConformInfo` for formatting, and `:checkhealth` for dependencies. `:checkhealth kickstart` checks the base requirements.

Lua formatting is checked on pushes to `master` and on pull requests. The previous workflow skipped this personal repository; that restriction has been removed.

## Validation

Validated in isolated XDG directories on Neovim 0.12.4 with the committed plugin lockfile. The smoke test passed startup, keymap checks, LuaLS attachment, actual Lua/Python/JavaScript/TypeScript formatting, snippet navigation, Markdown lint diagnostics, parser loading, and buffer deletion with unsaved-change cancellation. StyLua and `git diff --check` passed.

Gleam's native LSP configuration is enabled and checked by the test, but actual Gleam attachment was not tested because the Gleam executable is absent here. Terminal clipboard behavior and interactive picker appearance need a terminal session.

After first-run downloads finish, rerun the smoke test from this repository's root:

```sh
NVIM_APPNAME=nvim-migrated nvim --headless '+luafile tests/smoke.lua'
```

The test requires the configured Mason tools and Tree-sitter CLI. It opens Python, JavaScript, and TypeScript buffers, which may download their parsers on first use.
