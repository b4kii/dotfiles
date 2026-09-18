# nvim

Minimal Neovim 0.12 config in Lua. Cross-platform: Linux / macOS / Windows.

Plugin manager: **`vim.pack`** — built into Neovim 0.12. Nothing to bootstrap;
missing plugins clone themselves on the first start.

## Requirements

| What | For | Required? |
|---|---|---|
| Neovim >= 0.12 | `vim.pack`, `vim.hl`, `vim.lsp.completion` | **yes** |
| `git` in PATH | `vim.pack` uses it to clone plugins | **yes** |
| Nerd Font | icons in lualine / oil / which-key | no — set `vim.g.have_nerd_font = false` |
| `ripgrep` (`rg`) | `<leader>fg` (live grep) | no, but grep won't work without it |
| `fd` | faster `<leader>ff` | no |
| `tree-sitter` CLI >= 0.26 + C compiler | nvim-treesitter parsers | no — 6 parsers ship with Neovim |
| language servers | completion + diagnostics, per language | no — missing servers are skipped silently, see below |
| `stylua` / `prettier` / `ruff` / `shfmt` | `<leader>cf` (conform) | no — missing formatters are skipped silently |

## Language support

Everything below is optional and independent: install what you use, skip the
rest. Nothing here breaks the config when absent — `:LspMissing` lists which
configured servers were skipped because their binary is not in PATH.

| Language | Server | Install |
|---|---|---|
| PHP | intelephense | `npm i -g intelephense` |
| JS / TS / JSX / TSX | typescript-language-server | `npm i -g typescript@5 typescript-language-server` |
| HTML / CSS / SCSS / JSON | vscode-langservers-extracted | `npm i -g vscode-langservers-extracted` |
| ESLint | (same package) | — |
| Emmet (html, css, jsx, php) | emmet-language-server | `npm i -g @olrtg/emmet-language-server` |
| Lua | lua-language-server | `scoop install lua-language-server` |
| Python | pyright + ruff | `pip install pyright ruff` |

Everything except Lua in one go:

```bash
npm i -g intelephense typescript@5 typescript-language-server vscode-langservers-extracted @olrtg/emmet-language-server
```

**`typescript@5` is not a typo.** Plain `npm i -g typescript` now installs
TypeScript 7, the native Go rewrite, whose `lib/` contains only `tsc.js` and
`getExePath.js` — there is no `tsserver.js` anywhere in the package.
typescript-language-server needs that file and refuses to start without it:
*"Could not find a valid TypeScript installation"*. Pin the 5.x line until the
language server supports the native compiler.

typescript-language-server also ships no TypeScript of its own and normally
looks only inside the project's `node_modules`, so a scratch `.ts` file or a
project that has not run `npm install` yet gets no LSP at all. `lua/lsp.lua`
points it at the global install as a fallback — but only when the project has
no TypeScript of its own, so a pinned project version always wins.

Formatters (`<leader>cf`):

```bash
npm i -g prettier
```

```bash
composer global require friendsofphp/php-cs-fixer
```

**phpactor does not work on Windows** — its language-server mode needs the
`SIGINT` constant from the `pcntl` extension, which does not exist on Windows.
It exits 255 before the LSP handshake. Use intelephense there.

Treesitter parsers for the whole stack (php, html, css, scss, javascript,
typescript, tsx, jsdoc, phpdoc) are installed automatically when the
`tree-sitter` CLI and a C compiler are in PATH.

```bash
# Windows (scoop)
scoop install ripgrep fd tree-sitter lua-language-server
```

```bash
# macOS
brew install ripgrep fd tree-sitter lua-language-server
```

```bash
# Debian/Ubuntu
sudo apt install ripgrep fd-find && cargo install tree-sitter-cli
```

## Install

Two scripts do the whole thing — place the config, install every external tool,
then trigger the first plugin build. Both are idempotent: re-running them
reinstalls nothing and reports what is already present.

```powershell
.\install.ps1
```

```bash
./install.sh
```

| Flag | |
|---|---|
| `-SkipTools` / `--skip-tools` | only place the config and install plugins |
| `-SkipPlugins` / `--skip-plugins` | only install tools, do not start Neovim |
| `-Force` / `--force` | replace an existing config without asking |

An existing config is **moved** to `nvim.<timestamp>.bak`, never deleted. This
matters more than it sounds: Neovim loads `init.vim` *or* `init.lua`, never
both, so an old Vim config left in place silently wins.

The scripts install: ripgrep, fd, tree-sitter CLI, a C compiler, node, python,
the seven language servers, prettier, pyright and ruff. Windows uses scoop +
npm + pip; Linux/macOS detects apt, dnf, pacman, zypper, apk or brew. Anything
that cannot be installed is reported at the end rather than failing the run.

**Plugins are not installed by the scripts.** `vim.pack` clones them on first
start, pinned to the revisions in `nvim-pack-lock.json` — copy that file
between machines and you get identical plugin versions, the same way yazi's
`package.toml` pins its flavors.

### By hand

```bash
mv ~/.config/nvim ~/.config/nvim.bak && git clone <your-repo> ~/.config/nvim
```

```powershell
Move-Item "$env:LOCALAPPDATA\nvim" "$env:LOCALAPPDATA\nvim.bak"; git clone <your-repo> "$env:LOCALAPPDATA\nvim"
```

Run `nvim`. Plugins install themselves; `:LspMissing` lists the servers you
still need.

## Managing plugins

```vim
:lua vim.pack.update()                    " update everything; :w applies, :q discards
:lua vim.pack.update({'telescope.nvim'})  " update one
:lua vim.pack.update(nil, {offline=true}) " inspect what is installed
:lua vim.pack.del({'Comment.nvim'})       " remove from disk (drop it from plugins.lua first)
:checkhealth                              " diagnostics
```

Revisions are recorded in `nvim-pack-lock.json` under `stdpath('state')`. Copy
it between machines to pin identical plugin versions everywhere.

## Layout

```
install.ps1         installer: Windows  (scoop + npm + pip)
install.sh          installer: Linux / macOS  (apt|dnf|pacman|zypper|apk|brew)
init.lua            version guard, leader, load order
lua/options.lua     your `set ...` + clipboard + plugin minimums
lua/keymaps.lua     your keymaps (plugin ones live with their plugin)
lua/autocmds.lua    highlight_yank
lua/plugins.lua     vim.pack.add + setup + keymaps for every plugin
lua/lsp.lua         LSP without nvim-cmp and without Mason (optional)
```

## Plugins

| Plugin | For |
|---|---|
| telescope + plenary | fuzzy finder for files / text / buffers |
| oil.nvim | edit a directory like a normal buffer (replaces netrw) |
| gitsigns | git change markers in the gutter (signs only — no git operations) |
| lualine | statusline |
| which-key | keymap cheatsheet |
| vscode.nvim | colorscheme (VS Code Dark+ / Light+ port) |
| mini.icons | icons |
| nvim-treesitter | syntax highlighting |
| flash.nvim | jump anywhere on screen |
| mini.surround | add / delete / replace surrounding pairs |
| mini.pairs | auto-close brackets |
| conform.nvim | formatting (prettier / stylua / ruff / shfmt) |
| trouble.nvim | panel with diagnostics, references, symbols |
| todo-comments | highlight and search TODO / FIXME |
| indent-blankline | indent guides |
| Comment.nvim | treesitter-aware commenting (`gc` is built in) |
| blink.cmp | completion engine (Rust fuzzy ranking, snippet source) |
| friendly-snippets | snippet library surfaced by blink |
| nvim-lspconfig | source of LSP server configurations |

## Keymaps

Leader = `<Space>`. **Press `<leader>` and which-key shows the rest instantly**
(`delay = 0`). It is deliberately the *only* trigger: by default which-key also
hooks `g`, `z`, `]`, `[`, `"`, `<C-w>` and every other prefix, which with
`delay = 0` means the panel flashes constantly while you are just moving
around. `<leader>?` still lists everything, including those prefixes.

### Yours (unchanged)

| Key | Action |
|---|---|
| `<leader>w` / `<leader>q` | write file / close buffer |
| `<leader>h` | clear search highlight |
| `<leader>rr` | source the current file |
| `<leader>gh` `<leader>gl` `<leader>ge` | line start / line end / end of file |
| `<M-h>` / `<M-l>` | previous / next buffer |
| `<C-d>` / `<C-u>` | scroll half page, centered |
| `zj` / `zk` | blank line below / above |
| `<` `>` (visual) | indent, keep selection |

`<leader>e` now opens **oil** instead of `:Ex`.

### Plugins

| Key | Action |
|---|---|
| `<leader>ff` `<leader>fg` `<leader>fb` | telescope: find files / live grep / buffers |
| `<leader>fd` `<leader>fk` `<leader>fr` `<leader>f/` | diagnostics / help / resume / search in buffer |
| `<leader>e`, `-` | oil |
| `]c` / `[c` | next / previous git hunk |
| `gc` `gcc` | comment (built into Neovim since 0.10) |
| `<leader>?` | which-key: **all** keymaps at once |
| `s` / `S` | flash: jump to location / select treesitter node |
| `gsa` `gsd` `gsr` `gsf` | surround: add / delete / replace / find |
| `<leader>cf` | format buffer or selection |
| `<leader>xx` `<leader>xb` | trouble: workspace / buffer diagnostics |
| `<leader>xs` `<leader>xl` `<leader>xq` `<leader>xt` | trouble: symbols / LSP / quickfix / TODO |
| `<leader>ft` | telescope: TODO/FIXME list |
| `]t` / `[t` | next / previous TODO |
| `<leader>ub` | toggle dark / light |

Group labels (`+Telescope`, `+Git`, `+Trouble`, …) are defined in `wk.add({...})`
at the top of `lua/plugins.lua`. Every keymap here carries a `desc`, which is
what which-key displays — **add one to any mapping you write**, or it shows up
unlabelled.

### Completion

Handled by **blink.cmp**, configured in `lua/plugins.lua`. The menu opens on
every keystroke and ranks by match quality, so an exact match sits at the top
instead of somewhere down a list of hundreds.

| Key | |
|---|---|
| `<Tab>` / `<S-Tab>` | walk the list → jump snippet placeholders → literal Tab |
| `<CR>` | accept |
| `<C-n>` / `<C-p>`, arrows | walk the list |
| `<C-e>` | hide |
| `<C-space>` | show (only in terminals that send it) |

The keymap is written out (`preset = 'none'`) rather than using one of blink's
presets, so these keys do exactly what they did before blink was added.

Measured cost of the plugin on this machine: startup **161 ms → 206 ms**, and
4.8 MB on disk. Typing itself is faster than the native engine, not slower —
blink filters in Rust. `fuzzy.implementation` is set to
`prefer_rust_with_warning` so a missing binary complains loudly instead of
silently dropping to the slow Lua matcher, which would remove the one reason
the plugin is here.

**Why not the built-in `vim.lsp.completion`?** It works, and this config used it
for a while, but its `autotrigger` fires *only* on characters the server
declares in `completionProvider.triggerCharacters` — and none of them list
letters. Measured: intelephense declares `$ > : \ / ' " * . <`, ts_ls declares
`. " ' / @ <`. PHP therefore felt like it completed constantly (every variable
starts with `$`, every method call has `->`) while TypeScript felt dead, since
it only ever fires after a `.`. That was patchable by appending letters to the
list, but the ranking and the snippet library were not.

### Indent width

Your global 4-columns-with-hard-tabs stays the default, but `lua/autocmds.lua`
overrides it per language, because two levels of hard tabs render 8 columns
wide in HTML:

| Width | Languages |
|---|---|
| 2, spaces | html, css, scss, less, js, ts, jsx, tsx, vue, svelte, json, yaml, lua, markdown, xml |
| 4, spaces | php, python, sh, c, cpp, java, rust |
| 4, tabs | go (the one language that genuinely wants tabs) |

These match what prettier and each community actually use, so `<leader>cf` no
longer reformats against the editor. Anything not listed keeps your global 4.

### Emmet and tag jumping

Emmet works through the LSP: type an abbreviation such as `ul>li*3` and accept
the completion — it expands to the full markup with placeholders that `<Tab>`
moves between. It covers html, css, scss, jsx, tsx, vue and (added here) php.

`%` jumps between `<div>` and `</div>` with no configuration; Neovim's own
`plugin/matchit.vim` loads matchit by default. **The cursor has to be on the
tag name, not on the `<`** — `b:match_words` matches the name via a `<\@<=`
lookbehind. On `<` it falls back to plain bracket matching and appears broken.

### Snippets

Two sources, both in the same menu:

- **Language servers** — accepting `foreach` from intelephense or
  `div.row>ul>li*3` from emmet drops in the whole construct with placeholders.
- **friendly-snippets** — a library of ready-made snippets surfaced by blink's
  `snippets` source. In TypeScript, `ifac` gives `iface`, `ctor` gives a
  constructor, `log` gives `console.log`.

Snippets are language-scoped through friendly-snippets' `package.json`, so a
prefix that works in one filetype may not exist in another — `clg` is defined
for `javascriptreact`, not for plain `typescript`. Look in
`friendly-snippets/snippets/<lang>/` to see what a filetype actually has.

The engine is Neovim's own `vim.snippet` (blink is set to `preset = 'default'`).
`<Tab>` / `<S-Tab>` move between placeholders.

### LSP

`gd` is added in `lua/lsp.lua`, `:LspMissing` lists skipped servers. The rest
are **Neovim 0.11+ defaults**:
`K` hover, `grn` rename, `gra` code action, `grr` references, `gri`
implementation, `grt` type definition, `gO` document symbols, `]d`/`[d`
diagnostics, `<C-s>` (insert) signature help.

## Notes

- **Clipboard**: `g:clipboard = 'osc52'` is enabled **only over SSH**. Locally
  the native provider is used, because OSC52 cannot paste in most terminals.
  Want the old behaviour — see the comment in `lua/options.lua`.
- **`<M-h>` / `<M-l>` on macOS** need "Use Option as Meta key" in the terminal
  settings.
- **`Y` -> `y$`** and **`gc`/`gcc`** are Neovim defaults. The `Y` mapping is
  kept for parity; Comment.nvim can be dropped.
- **`set encoding=utf-8`** dropped — Neovim is always UTF-8.
- **Enter does not expand brackets.** mini.pairs maps `<CR>` by default, turning
  `foo(|)` into three lines with the `)` pushed down past a blank one. That
  mapping is removed, so Enter just breaks the line. `<BS>` is kept: deleting
  the opening bracket of an empty pair takes the closing one with it. Auto-close
  itself is still on — typing `(` gives `()`.
- **Indentation while typing is split by language, on purpose.** The bundled Vim
  indent scripts only reindent on demand — `gg=G` formats a PHP file correctly,
  but pressing Enter after `function foo() {` leaves the new line at column 0.
  That is stock Neovim, identical under `nvim --clean`. Treesitter indentation
  fixes it for most languages but **not** PHP: mid-typing the `{` has no match
  yet, so the parser yields an ERROR node instead of the `compound_statement`
  that `php/indents.scm` keys off. Measured while typing: lua/css/html correct,
  typescript correct but loses a level on deep nesting, php nothing at all. So
  PHP uses `cindent` (its syntax is C-like) and everything else uses treesitter.
  Note `indentexpr` overrides `cindent` completely, so the PHP branch has to
  clear it — setting `cindent` alone silently does nothing.
- **`s` belongs to flash, not to surround.** flash.nvim and mini.surround both
  claim `s` by default. Resolved in favour of flash, surround moved to `gs*`.
  Built-in `s` is just an alias for `cl` and `gs` is "sleep N seconds", so
  neither loss matters. To swap them, edit `mappings` in the mini.surround
  section and the flash keys in `lua/plugins.lua`.
- **conform only formats with what is in PATH.** Missing formatters are skipped
  silently, so nothing breaks on a machine without `prettier`. Run
  `:ConformInfo` to see what is picked up for the current filetype.
- **The colorscheme has a light variant.** `<leader>ub` toggles Dark+ / Light+
  at runtime. To make light the default, change `vim.o.background` in
  `lua/plugins.lua`.
- **Git operations are not in Neovim — lazygit does them.** gitsigns is kept
  only for the gutter markers and `]c` / `[c` hunk navigation, which is the one
  thing lazygit cannot do: annotate the buffer while you type. No stage / reset
  / blame / diff keymaps, so `<leader>g` stays yours for goto, exactly as in
  your original `init.vim`. To add them back, give `gitsigns.setup` an
  `on_attach` with the mappings you want in `lua/plugins.lua`.
