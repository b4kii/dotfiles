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
  'https://github.com/kdheepak/lazygit.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/debugloop/telescope-undo.nvim',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/nvim-mini/mini.icons',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/Mofiqul/vscode.nvim',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },

  -- motion / editing
  'https://github.com/folke/flash.nvim',
  'https://github.com/nvim-mini/mini.surround',
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

-- Praca, ktora nie musi byc skonczona, zanim pojawi sie pierwsza klatka.
-- `vim.schedule` na koncu tego pliku odpala ja natychmiast po tym, jak Neovim
-- zakonczy start -- czyli zanim zdazysz cokolwiek nacisnac, ale juz PO
-- narysowaniu okna.
--
-- Wazne, zeby nie miec zludzen: to NIE usuwa pracy. Procesor robi dokladnie
-- tyle samo, tylko przestaje blokowac rysowanie. Okno pojawia sie wczesniej,
-- laczny czas do pelnej gotowosci jest ten sam.
--
-- Trafiaja tu wylacznie SETUPY. Keymapy zostaja synchroniczne, bo one musza
-- istniec od razu -- inaczej klawisz nacisniety w pierwszej chwili poszedlby
-- w domyslne zachowanie Vima.
local defer = {}

-- --- which-key -------------------------------------------------------------
local wk = require('which-key')
wk.setup({
  preset = 'helix',   -- centered panel; alternatives: 'classic', 'modern'
  delay = 0,          -- ms before the popup appears; 0 = instant
  icons = { mappings = vim.g.have_nerd_font },

  -- ONLY <leader> opens the cheatsheet. Out of the box which-key hooks every
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
-- 5 ms, odlozone. Zaden picker nie jest potrzebny przed pierwszym <leader>f.
defer[#defer + 1] = function()
  require('telescope').setup({
    defaults = {
      path_display = { 'truncate' },
      mappings = { i = { ['<Esc>'] = 'close', ['<C-u>'] = false } },
    },
    pickers = {
      find_files = { hidden = true },
    },
  })
  -- Musi byc PO setupie telescope i dlatego siedzi w tej samej odlozonej
  -- funkcji -- load_extension na nieskonfigurowanym telescope wywala blad.
  require('telescope').load_extension('undo')
end

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

-- --- telescope-undo --------------------------------------------------------
-- Lokalna historia pliku, bez gita. Vim trzyma zmiany jako DRZEWO, nie liste:
-- jesli cofniesz sie i napiszesz cos innego, stara wersja nadal tam jest --
-- tyle ze `u` juz do niej nie trafi, bo chodzi tylko po jednej galezi.
--
-- Ten picker splaszcza drzewo do listy, ale pozwala szukac PO TRESCI zmian
-- ("gdzie jest ta funkcja, ktora skasowalem godzine temu") i przez <C-y>
-- wyjankowac sam fragment BEZ cofania bufora.
--
-- Siega tak daleko, jak 'undofile' (wlaczone w options.lua) -- bez niego
-- historia konczy sie z zamknieciem pliku.
--
-- Diffy liczy wbudowanym vim.diff, wiec nie potrzebuje `diff` w PATH.
-- Samo rozszerzenie wczytuje sie przy setupie telescope, wyzej.
map('n', '<leader>uu', function() require('telescope').extensions.undo.undo() end,
  { desc = 'UI: undo history' })

-- --- lualine ---------------------------------------------------------------
-- 12 ms, odlozone. Statusline pojawia sie o jedna klatke pozniej.
defer[#defer + 1] = function()
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
end

-- Comment.nvim was removed: it hijacked gc/gcc and then failed on PHP
-- ("[Comment.nvim] nil", line left untouched). Neovim's built-in gc/gcc has
-- worked since 0.10 and handles PHP fine, so there is nothing to replace.
vim.keymap.set("n", "<C-/>", "gcc", { remap = true })   

-- --- nvim-treesitter (branch `main`) ---------------------------------------
-- Building parsers needs the `tree-sitter` CLI (>= 0.26), a C compiler and
-- curl/tar in PATH. Without the CLI parser installation is skipped and the
-- rest still works (0.12 ships parsers for c/lua/vim/vimdoc/markdown/query).
require('nvim-treesitter').setup()

-- The tree-sitter CLI only drives the build -- the actual compiling is done by
-- a C compiler, and without one every parser dies with
--   "Failed to execute the C compiler ... Error: program not found"
-- once per Neovim start. So check for one first and say so plainly instead of
-- letting that wall of red scroll past.
--
-- On Windows that check is NOT "is there a compiler in PATH". The CLI's `cc`
-- backend targets MSVC and finds `cl.exe` through vswhere and the registry:
--   * `cl` is usually absent from PATH even where every parser builds fine --
--     putting it there is what vcvarsall.bat is for, and this does not need it;
--   * a MinGW gcc in PATH is never consulted. Verified by inspecting a built
--     parser: with gcc first in PATH it still links against VCRUNTIME140.
--     Forcing it with CC=gcc does switch compilers, and then MinGW's ld refuses
--     the \\?\-prefixed output path the CLI hands it ("cannot open output
--     file ... Invalid argument"). gcc is simply not an answer on Windows.
-- Probing for gcc here is what used to let install() run on a machine that
-- could not possibly compile anything.
local function c_compiler()
  if vim.fn.has('win32') == 1 then
    if vim.env.CC and vim.env.CC ~= '' then return vim.env.CC end

    local vswhere = vim.fs.joinpath(
      vim.env['ProgramFiles(x86)'] or 'C:/Program Files (x86)',
      'Microsoft Visual Studio', 'Installer', 'vswhere.exe')
    if vim.uv.fs_stat(vswhere) then
      -- -requires, not a bare -latest: Build Tools installs with no C++
      -- workload exist, and they contain no cl.exe.
      local r = vim.system({
        vswhere, '-products', '*', '-latest',
        '-requires', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
        '-property', 'installationPath',
      }, { text = true }):wait()
      if r.code == 0 and r.stdout and r.stdout:match('%S') then
        return 'cl.exe (' .. vim.trim(r.stdout) .. ')'
      end
    end

    return vim.fn.executable('cl') == 1 and 'cl' or nil
  end

  for _, exe in ipairs({ 'cc', 'gcc', 'clang' }) do
    if vim.fn.executable(exe) == 1 then return exe end
  end
  return nil
end

if vim.fn.executable('tree-sitter') == 1 then
  local want = {
    -- no 'jsonc' here: it has no parser of its own, `json` covers it
    'lua', 'vim', 'vimdoc', 'query', 'bash', 'json', 'yaml', 'toml',
    'markdown', 'markdown_inline', 'diff', 'gitcommit', 'regex',
    -- web stack
    'php', 'phpdoc', 'html', 'css', 'scss', 'powershell',
    'javascript', 'typescript', 'tsx', 'jsdoc',
  }
  local ts = require('nvim-treesitter')
  local have = (ts.get_installed and ts.get_installed()) or {}
  local missing = vim.tbl_filter(function(p) return not vim.tbl_contains(have, p) end, want)

  if #missing > 0 then
    local cc = c_compiler()
    if cc then
      ts.install(missing)
    else
      -- Once per session, not on every FileType event.
      local hint = vim.fn.has('win32') == 1
        and 'Windows needs MSVC -- gcc will not do:\n'
          .. 'winget install --id Microsoft.VisualStudio.BuildTools -e --override '
          .. '"--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"'
        or (vim.fn.has('mac') == 1
          and 'macOS: xcode-select --install'
          or 'Linux: apt install build-essential  (or the distro equivalent)')

      vim.schedule(function()
        vim.notify(
          ('nvim-treesitter: %d parser(s) missing, but no C compiler was found.\n')
            :format(#missing)
          .. 'Highlighting still works for the parsers bundled with Neovim.\n'
          .. hint,
          vim.log.levels.WARN
        )
      end)
    end
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
  desc = 'Start treesitter and use its indentation when a parser exists',
  callback = function(args)
    -- Nie `return` przy porazce: ps1 nie ma parsera, a i tak potrzebuje wciec.
    local ts_ok = pcall(vim.treesitter.start, args.buf)
    local ft = vim.bo[args.buf].filetype

    -- PHP: php/indents.scm keyuje na `compound_statement`, a dopoki piszesz,
    -- `{` nie ma pary i parser daje ERROR -- nic nie wciska. Poza tym wszedzie,
    -- gdzie runtime wybral `smartindent` (u nas tylko ps1), bierzemy `cindent`:
    -- ta sama klasa jezykow, ale bez doliczania poziomu dwa razy, co dawalo
    -- kursor o poziom glebiej niz klamra.
    local lang = ts_ok and vim.treesitter.language.get_lang(ft) or nil
    local ts_indent = ft ~= 'php'
      and lang ~= nil
      and vim.treesitter.query.get(lang, 'indents') ~= nil

    if ts_indent then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    elseif ft == 'php' or vim.bo[args.buf].smartindent then
      -- `indentexpr` MUSI zniknac: ustawione wygrywa z `cindent` calkowicie.
      vim.bo[args.buf].indentexpr = ''
      vim.bo[args.buf].smartindent = false
      vim.bo[args.buf].cindent = true
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
-- Panel jest czysto na zadanie, wiec setup moze poczekac.
defer[#defer + 1] = function() require('trouble').setup() end

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

map('n', '<leader>lg', '<Cmd>LazyGit<CR>', {
  desc = 'LazyGit',
})

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
--
-- 23 ms -- najdrozsza pojedyncza rzecz w calym starcie, wiec odlozona.
-- Bezpiecznie, bo uzupelnianie jest potrzebne dopiero po wejsciu w tryb
-- wstawiania, a schedule odpala sie duzo wczesniej. `get_lsp_capabilities()`
-- wolane w lua/lsp.lua NIE wymaga setupu -- czyta wartosci domyslne.
defer[#defer + 1] = function()
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
      -- Bez domykania: akceptacja funkcji wstawia sama nazwe, bez `()`.
      accept = { auto_brackets = { enabled = false } },
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
end

-- --- indent-blankline (the module is called `ibl`) -------------------------
-- Vertical indent guides. `scope` (highlighting the current block) is off --
-- it needs a treesitter parser for the language and tends to flicker.
require('ibl').setup({
  indent = { char = '│' },
  scope = { enabled = false },
  exclude = { filetypes = { 'help', 'lazy', 'oil', 'trouble', 'checkhealth' } },
})

-- --- odlozone setupy -------------------------------------------------------
-- Wszystko, co powyzej trafilo do `defer`. Jeden schedule, nie kilka: kolejnosc
-- zostaje taka jak w pliku, a Neovim budzi sie z tym raz zamiast pieciokrotnie.
--
-- Celowo NIE ma tu: oil (musi byc gotowy zanim `nvim .` otworzy katalog),
-- gitsigns i indent-blankline (podpinaja sie do bufora otwartego juz przy
-- starcie), which-key i mini.* (grosze, nie warto komplikowac pliku).
vim.schedule(function()
  for _, setup in ipairs(defer) do
    setup()
  end
end)
