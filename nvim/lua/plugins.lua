-- ===========================================================================
--  plugins.lua -- vim.pack (built into Neovim 0.12)
--
--  `confirm = false` => missing plugins install themselves, no prompt.
--  While init.lua is sourced vim.pack behaves like `:packadd!`: runtimepath is
--  set immediately (so `require` below works), and plugin/ + ftdetect/ dirs
--  are sourced normally once init.lua finishes.
-- ===========================================================================

vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/nvim-mini/mini.icons',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/Mofiqul/vscode.nvim',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },

  -- motion / editing
  'https://github.com/folke/flash.nvim',
  'https://github.com/nvim-mini/mini.surround',
  'https://github.com/nvim-mini/mini.pairs',
  'https://github.com/stevearc/conform.nvim',

  -- diagnostics / annotations
  'https://github.com/folke/trouble.nvim',
  'https://github.com/folke/todo-comments.nvim',
  'https://github.com/lukas-reineke/indent-blankline.nvim',

  -- completion. Pinned to 1.* because blink ships a prebuilt Rust matcher per
  -- tagged release; tracking the branch would leave you without the binary.
  'https://github.com/rafamadriz/friendly-snippets',
  { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('1.*') },
}, { confirm = false })

local map = vim.keymap.set

-- --- which-key -------------------------------------------------------------
-- Press a prefix (<leader>, g, z, ], [, ", <C-w>) and the cheatsheet pops up
-- after `delay` ms. Labels come from the `desc` field of every keymap, so any
-- new mapping you add should carry one.
local wk = require('which-key')
wk.setup({
  preset = 'helix',   -- centered panel; alternatives: 'classic', 'modern'
  delay = 0,          -- ms before the popup appears; 0 = instant
  icons = { mappings = vim.g.have_nerd_font },

  -- ONLY <leader> opens the cheatsheet. Out of the box which-key hooks every
  -- prefix it can find -- g, z, ], [, ", ', `, <C-w> -- so with delay = 0 the
  -- panel flashes constantly while you are just moving around. Restricting the
  -- triggers keeps normal-mode motions silent.
  triggers = {
    { '<leader>', mode = { 'n', 'v' } },
  },
})

wk.add({
  { '<leader>f', group = 'Telescope' },
  { '<leader>g', group = 'Goto' },
  { '<leader>x', group = 'Trouble' },
  { '<leader>c', group = 'Code' },
  { '<leader>u', group = 'UI' },
  { '<leader>r', group = 'Reload' },
  { 'gr', group = 'LSP' },
  { 'gs', group = 'Surround' },
  { ']', group = 'Next' },
  { '[', group = 'Previous' },
})

map('n', '<leader>?', function() wk.show({ global = true }) end,
  { desc = 'which-key: all keymaps' })

-- --- vscode.nvim (VS Code Dark+ / Light+ port) -----------------------------
-- The variant follows `background`: dark -> Dark+, light -> Light+.
vim.o.background = 'dark'

require('vscode').setup({
  transparent = false,     -- true = terminal background instead of theme's
  italic_comments = true,
  underline_links = true,
  terminal_colors = true,  -- :terminal colors match the VS Code palette
})
-- Yellow cursor. This has to be re-applied on every ColorScheme event: loading
-- a theme resets every highlight group, so setting `Cursor` once would survive
-- until the first <leader>ub toggle and then silently go back to default.
local function yellow_cursor()
  vim.api.nvim_set_hl(0, 'Cursor', { fg = '#000000', bg = '#fafa33' })
  vim.api.nvim_set_hl(0, 'lCursor', { fg = '#000000', bg = '#fafa33' })
  vim.api.nvim_set_hl(0, 'TermCursor', { fg = '#000000', bg = '#fafa33' })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('yellow_cursor', { clear = true }),
  desc = 'Keep the cursor yellow after a colorscheme change',
  callback = yellow_cursor,
})

-- registered above, so this call already triggers yellow_cursor()
vim.cmd.colorscheme('vscode')

map('n', '<leader>ub', function()
  vim.o.background = (vim.o.background == 'dark') and 'light' or 'dark'
  vim.cmd.colorscheme('vscode')
  vim.notify('background = ' .. vim.o.background)
end, { desc = 'UI: toggle dark/light' })

-- --- mini.icons ------------------------------------------------------------
-- Pure Lua, no dependencies. Set have_nerd_font = false in init.lua to fall
-- back to plain ASCII glyphs.
require('mini.icons').setup({ style = vim.g.have_nerd_font and 'glyph' or 'ascii' })
MiniIcons.mock_nvim_web_devicons() -- so telescope/lualine pick them up

-- --- telescope -------------------------------------------------------------
-- live_grep needs ripgrep (`rg`) in PATH. find_files works without it, but is
-- much faster with `fd`/`rg`. See README.md for install commands.
require('telescope').setup({
  defaults = {
    path_display = { 'truncate' },
    mappings = { i = { ['<Esc>'] = 'close', ['<C-u>'] = false } },
  },
  pickers = {
    find_files = { hidden = true },
  },
})

local function tb(fn, opts)
  return function() require('telescope.builtin')[fn](opts) end
end

map('n', '<leader>ff', tb('find_files'), { desc = 'Telescope: find files' })
map('n', '<leader>fg', tb('live_grep'), { desc = 'Telescope: live grep' })
map('n', '<leader>fb', tb('buffers'), { desc = 'Telescope: buffers' })
map('n', '<leader>fd', tb('diagnostics'), { desc = 'Telescope: diagnostics' })
map('n', '<leader>fk', tb('help_tags'), { desc = 'Telescope: help tags' })
map('n', '<leader>fr', tb('resume'), { desc = 'Telescope: resume last picker' })
map('n', '<leader>f/', tb('current_buffer_fuzzy_find'), { desc = 'Telescope: search in buffer' })

-- --- oil.nvim --------------------------------------------------------------
-- Replaces netrw. A directory is a normal buffer: edit it like text and `:w`
-- to apply the changes on disk.
require('oil').setup({
  default_file_explorer = true,
  view_options = { show_hidden = true },
  use_default_keymaps = true,
})

map('n', '<leader>e', '<Cmd>Oil<CR>', { desc = 'Oil: file explorer' })
map('n', '-', '<Cmd>Oil<CR>', { desc = 'Oil: parent directory' })

-- --- gitsigns (signs only) -------------------------------------------------
-- Gutter markers for added/changed/deleted lines, plus ]c / [c to jump between
-- them. Deliberately NO stage / reset / blame / diff keymaps -- that is what
-- lazygit is for. This is the one thing lazygit cannot do: annotate the buffer
-- while you type. It also keeps <leader>g free for your own goto mappings.
require('gitsigns').setup({
  on_attach = function(bufnr)
    local gs = require('gitsigns')
    map('n', ']c', function() gs.nav_hunk('next') end,
      { buffer = bufnr, desc = 'Git: next hunk' })
    map('n', '[c', function() gs.nav_hunk('prev') end,
      { buffer = bufnr, desc = 'Git: previous hunk' })
  end,
})

-- --- lualine ---------------------------------------------------------------
require('lualine').setup({
  options = {
    theme = 'auto',
    icons_enabled = vim.g.have_nerd_font,
    component_separators = '|',
    section_separators = '',
    globalstatus = true, -- one statusline at the bottom, not per window
  },
  sections = {
    -- Set explicitly rather than relying on the default. `diff` reads its
    -- counts from gitsigns, so it costs nothing extra; without gitsigns it
    -- would shell out to `git diff` on every refresh.
    lualine_b = { 'branch', 'diff' },
    lualine_c = { { 'filename', path = 1 } },
    lualine_x = { 'diagnostics', 'filetype' },
  },
})

-- Comment.nvim was removed: it hijacked gc/gcc and then failed on PHP
-- ("[Comment.nvim] nil", line left untouched). Neovim's built-in gc/gcc has
-- worked since 0.10 and handles PHP fine, so there is nothing to replace.

-- --- nvim-treesitter (branch `main`) ---------------------------------------
-- Building parsers needs the `tree-sitter` CLI (>= 0.26), a C compiler and
-- curl/tar in PATH. Without the CLI parser installation is skipped and the
-- rest still works (0.12 ships parsers for c/lua/vim/vimdoc/markdown/query).
require('nvim-treesitter').setup()

if vim.fn.executable('tree-sitter') == 1 then
  local want = {
    -- no 'jsonc' here: it has no parser of its own, `json` covers it
    'lua', 'vim', 'vimdoc', 'query', 'bash', 'json', 'yaml', 'toml',
    'markdown', 'markdown_inline', 'diff', 'gitcommit', 'regex',
    -- web stack
    'php', 'phpdoc', 'html', 'css', 'scss',
    'javascript', 'typescript', 'tsx', 'jsdoc',
  }
  local ts = require('nvim-treesitter')
  local have = (ts.get_installed and ts.get_installed()) or {}
  local missing = vim.tbl_filter(function(p) return not vim.tbl_contains(have, p) end, want)
  if #missing > 0 then
    ts.install(missing)
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
  desc = 'Start treesitter and use its indentation when a parser exists',
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then return end

    -- Automatic indentation while typing.
    --
    -- The bundled Vim indent scripts only reindent on demand: `gg=G` formats a
    -- PHP file correctly, but pressing Enter after `function foo() {` leaves
    -- the new line at column 0. That is stock Neovim behaviour, identical
    -- under `nvim --clean` -- not something this config broke.
    --
    -- Treesitter indentation fixes it for most languages, but NOT for PHP:
    -- while you are still typing, `{` has no matching `}` yet, so the parser
    -- produces an ERROR node instead of the `compound_statement` that
    -- php/indents.scm keys off, and nothing matches. Measured while typing:
    --   lua, css, html  -> correct
    --   typescript      -> correct, loses a level on deep nesting
    --   php             -> no indentation at all
    -- `cindent` handles PHP perfectly (the syntax is C-like), so PHP gets that
    -- instead. Either way `=` / `gg=G` reindents a whole file properly.
    local ft = vim.bo[args.buf].filetype

    if ft == 'php' then
      -- `indentexpr` MUST be cleared: when it is set it wins over `cindent`
      -- entirely, so leaving GetPhpIndent() in place makes `cindent` dead code.
      vim.bo[args.buf].indentexpr = ''
      vim.bo[args.buf].cindent = true
      return
    end

    local lang = vim.treesitter.language.get_lang(ft)
    if lang and vim.treesitter.query.get(lang, 'indents') then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- --- flash.nvim ------------------------------------------------------------
-- `s` + two characters labels every match; press the label to jump there. Also
-- works as an operator target: `ds<chars><label>` deletes up to that spot.
-- `S` jumps between treesitter nodes. It also enhances f/t/F/T.
require('flash').setup()

map({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end,
  { desc = 'Flash: jump to location' })
map({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end,
  { desc = 'Flash: select treesitter node' })
map('o', 'r', function() require('flash').remote() end,
  { desc = 'Flash: remote operation' })

-- --- mini.surround ---------------------------------------------------------
-- Default prefix is `s`, which flash already took, so it moves to `gs`
-- (built-in `gs` is "sleep N seconds" -- no real loss). Same choice LazyVim
-- makes.
--
--   gsaiw"   surround word with quotes     gsd"   delete surrounding quotes
--   gsr"'    replace " with '              gsf"   find next
require('mini.surround').setup({
  mappings = {
    add = 'gsa',
    delete = 'gsd',
    find = 'gsf',
    find_left = 'gsF',
    highlight = 'gsh',
    replace = 'gsr',
    update_n_lines = 'gsn',
    suffix_last = 'l',
    suffix_next = 'n',
  },
})

-- --- mini.pairs ------------------------------------------------------------
-- Auto-closes ( [ { " ' `. Skips closing when the cursor sits before a letter
-- or digit, so it stays out of the way when appending to an existing word.
require('mini.pairs').setup()

-- mini.pairs also maps <CR> and <BS> on its own. The <CR> one turns `foo(|)`
-- into three lines, pushing the `)` down onto its own line. Removed -- Enter
-- now just breaks the line like it normally would. <BS> is kept: deleting the
-- opening bracket of an empty pair takes the closing one with it, which is
-- the behaviour that stops `()` leftovers.
pcall(vim.keymap.del, 'i', '<CR>')

-- --- conform.nvim ----------------------------------------------------------
-- Formatting via external tools. Only the ones present in PATH are used --
-- missing formatters are skipped silently, so this is safe on every machine.
-- `lsp_format = 'fallback'` means: no formatter but an LSP that can format
-- -> let the LSP do it. Run `:ConformInfo` to see what is picked up.
require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_format' },
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    typescript = { 'prettierd', 'prettier', stop_after_first = true },
    javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    html = { 'prettierd', 'prettier', stop_after_first = true },
    css = { 'prettierd', 'prettier', stop_after_first = true },
    scss = { 'prettierd', 'prettier', stop_after_first = true },
    less = { 'prettierd', 'prettier', stop_after_first = true },
    json = { 'prettierd', 'prettier', stop_after_first = true },
    jsonc = { 'prettierd', 'prettier', stop_after_first = true },
    yaml = { 'prettierd', 'prettier', stop_after_first = true },
    markdown = { 'prettierd', 'prettier', stop_after_first = true },
    -- PHP: pint (Laravel) if the project has it, otherwise php-cs-fixer
    php = { 'pint', 'php_cs_fixer', stop_after_first = true },
    sh = { 'shfmt' },
  },
})

map({ 'n', 'v' }, '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Code: format buffer/selection' })

-- --- trouble.nvim ----------------------------------------------------------
-- Every error / reference / symbol in one panel instead of hopping with ]d.
-- The panel is a normal window: <CR> jumps to the location, q closes it.
require('trouble').setup()

map('n', '<leader>xx', '<Cmd>Trouble diagnostics toggle<CR>',
  { desc = 'Trouble: workspace diagnostics' })
map('n', '<leader>xb', '<Cmd>Trouble diagnostics toggle filter.buf=0<CR>',
  { desc = 'Trouble: buffer diagnostics' })
map('n', '<leader>xs', '<Cmd>Trouble symbols toggle win.position=right<CR>',
  { desc = 'Trouble: symbols outline' })
map('n', '<leader>xl', '<Cmd>Trouble lsp toggle win.position=right<CR>',
  { desc = 'Trouble: LSP definitions/references' })
map('n', '<leader>xq', '<Cmd>Trouble qflist toggle<CR>',
  { desc = 'Trouble: quickfix list' })

-- --- todo-comments ---------------------------------------------------------
-- Highlights TODO / FIXME / HACK / NOTE / WARN / PERF in comments and makes
-- them searchable.
require('todo-comments').setup({ signs = true })

map('n', '<leader>ft', '<Cmd>TodoTelescope<CR>', { desc = 'Telescope: TODO/FIXME' })
map('n', '<leader>xt', '<Cmd>Trouble todo toggle<CR>', { desc = 'Trouble: TODO/FIXME' })
map('n', ']t', function() require('todo-comments').jump_next() end,
  { desc = 'Todo: next comment' })
map('n', '[t', function() require('todo-comments').jump_prev() end,
  { desc = 'Todo: previous comment' })

-- --- blink.cmp -------------------------------------------------------------
-- Replaces the built-in `vim.lsp.completion`. What it buys over native:
-- fuzzy ranking (an exact match lands at the top instead of somewhere down a
-- list of hundreds), the friendly-snippets library, and a documentation panel.
-- Measured cost on this machine: about +44 ms of startup and 4.8 MB on disk.
-- It filters in Rust, so typing itself is faster than native, not slower.
--
-- The keymap is written out rather than using a preset so the keys keep doing
-- exactly what they did before blink arrived: <Tab> walks the list, then jumps
-- snippet placeholders, then falls through to a literal Tab.
require('blink.cmp').setup({
  snippets = { preset = 'default' }, -- vim.snippet, same engine as before
  sources = {
    default = { 'lsp', 'snippets', 'path', 'buffer' },
  },
  fuzzy = {
    -- Refuse to silently fall back to the Lua matcher: without the Rust
    -- binary the ranking that justifies this plugin is the thing you lose.
    implementation = 'prefer_rust_with_warning',
  },
  completion = {
    list = { selection = { preselect = false, auto_insert = false } },
    menu = { draw = { treesitter = { 'lsp' } } },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    ghost_text = { enabled = false }, -- set true for the inline preview
  },
  signature = { enabled = true },
  keymap = {
    preset = 'none',
    ['<Tab>']     = { 'select_next', 'snippet_forward', 'fallback' },
    ['<S-Tab>']   = { 'select_prev', 'snippet_backward', 'fallback' },
    ['<CR>']      = { 'accept', 'fallback' },
    ['<C-e>']     = { 'hide', 'fallback' },
    ['<C-n>']     = { 'select_next', 'fallback' },
    ['<C-p>']     = { 'select_prev', 'fallback' },
    ['<Down>']    = { 'select_next', 'fallback' },
    ['<Up>']      = { 'select_prev', 'fallback' },
    ['<C-space>'] = { 'show', 'hide' },
  },
})

-- --- indent-blankline (the module is called `ibl`) -------------------------
-- Vertical indent guides. `scope` (highlighting the current block) is off --
-- it needs a treesitter parser for the language and tends to flicker.
require('ibl').setup({
  indent = { char = '│' },
  scope = { enabled = false },
  exclude = { filetypes = { 'help', 'lazy', 'oil', 'trouble', 'checkhealth' } },
})
