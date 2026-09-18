-- ===========================================================================
--  lsp.lua -- LSP without nvim-cmp, without Mason, without ceremony.
--
--  Neovim 0.11+ has its own API (`vim.lsp.config` / `vim.lsp.enable`) and
--  built-in completion (`vim.lsp.completion`). nvim-lspconfig is here only as
--  a provider of ready-made lsp/*.lua files -- it is never called directly.
--
--  Do not want LSP? Delete this file and the `require('lsp')` line in init.lua.
-- ===========================================================================

vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' }, { confirm = false })

-- Servers to bring up. Names match nvim-lspconfig/lsp/*.lua.
-- server name -> the binary it needs in PATH.
--
-- The binary is listed explicitly on purpose. Several lspconfig entries define
-- `cmd` as a FUNCTION (it resolves node_modules first, then the global
-- install), so there is no table to read the executable from and a naive guard
-- would enable them even when nothing is installed.
local servers = {
  lua_ls                = 'lua-language-server',
  intelephense          = 'intelephense',
  ts_ls                 = 'typescript-language-server',
  html                  = 'vscode-html-language-server',
  cssls                 = 'vscode-css-language-server',
  jsonls                = 'vscode-json-language-server',
  eslint                = 'vscode-eslint-language-server',
  emmet_language_server = 'emmet-language-server',
  pyright               = 'pyright-langserver', -- Python: types, completion
  ruff                  = 'ruff',               -- Python: linting, fast fixes
  -- gopls = 'gopls', clangd = 'clangd',
  -- rust_analyzer = 'rust-analyzer', bashls = 'bash-language-server',
}

-- Not 'phpactor': its language-server mode needs the SIGINT constant from the
-- pcntl extension, which does not exist on Windows. It crashes with exit 255
-- ("Undefined constant ...\Server\SIGINT") before the handshake. Fine on
-- Linux/macOS -- add it back there if you prefer it over intelephense.

-- typescript-language-server ships no TypeScript of its own. It looks for one
-- in the project's node_modules and refuses to start without it ("Could not
-- find a valid TypeScript installation"), which makes scratch .ts files and
-- projects that have not run `npm install` yet completely dead.
--
-- So: point it at the globally installed TypeScript, but ONLY when the project
-- has none of its own -- a project pinned to its own version must keep using
-- it, or you get diagnostics that do not match what `tsc` reports in CI.
local function global_tsserver_lib()
  local exe = vim.fn.exepath('typescript-language-server')
  if exe == '' then return nil end
  local dir = vim.fs.dirname(exe)
  for _, p in ipairs({
    dir .. '/node_modules/typescript/lib',                       -- npm -g on Windows
    vim.fs.dirname(dir) .. '/lib/node_modules/typescript/lib',   -- npm -g on unix
    dir .. '/../lib/node_modules/typescript/lib',
  }) do
    if vim.uv.fs_stat(p .. '/tsserver.js') then return vim.fs.normalize(p) end
  end
end

local tslib = global_tsserver_lib()
if tslib then
  vim.lsp.config('ts_ls', {
    before_init = function(params, config)
      local root = params.rootPath
      if not root and params.workspaceFolders and params.workspaceFolders[1] then
        root = vim.uri_to_fname(params.workspaceFolders[1].uri)
      end
      -- project has its own TypeScript -> leave the server alone
      if root and vim.uv.fs_stat(root .. '/node_modules/typescript/lib/tsserver.js') then
        return
      end
      -- NOTE: mutate `params`, not `config`. client.lua builds
      -- `initializationOptions = config.init_options` BEFORE it calls
      -- before_init, so assigning to config.init_options here is too late and
      -- silently does nothing. (config.settings IS still read afterwards --
      -- that is why the docs' own example mutates settings.)
      params.initializationOptions = vim.tbl_deep_extend('force',
        params.initializationOptions or {},
        { hostInfo = 'neovim', tsserver = { path = tslib } })
    end,
  })
end

-- Root directory fallback.
--
-- Servers locate a project by looking for marker files -- intelephense wants
-- `composer.json` or `.git`. When none is found `root_dir` stays nil, the
-- server still attaches but runs in single-file mode: it indexes only the open
-- buffer. A `require_once './utils.php'` is then invisible, so a function
-- defined next door stops being suggested. Deleting a `.git` directory is
-- enough to trigger this, which looks exactly like the LSP breaking.
--
-- So: keep the normal marker search, and when it finds nothing fall back to
-- the directory the file lives in. A plain folder with two PHP files then
-- works without having to `git init` it or drop in a stub composer.json.
local root_fallback = {
  intelephense = { 'composer.json', '.git' },
  ts_ls        = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  cssls        = { 'package.json', '.git' },
  html         = { 'package.json', '.git' },
  jsonls       = { 'package.json', '.git' },
}

for name, markers in pairs(root_fallback) do
  vim.lsp.config(name, {
    root_dir = function(bufnr, on_dir)
      local fname = vim.api.nvim_buf_get_name(bufnr)
      -- unnamed buffer: nothing sensible to root to, let the server decide
      if fname == '' then return on_dir(nil) end
      on_dir(vim.fs.root(fname, markers) or vim.fs.dirname(fname))
    end,
  })
end

-- eslint and emmet are deliberately left out: eslint is meaningless without a
-- config file to find, and emmet does not care about a workspace at all.

-- Emmet does not claim php by default, but .php files are mostly HTML.
vim.lsp.config('emmet_language_server', {
  filetypes = {
    'astro', 'css', 'eruby', 'html', 'htmlangular', 'htmldjango',
    'javascriptreact', 'less', 'php', 'sass', 'scss', 'svelte',
    'typescriptreact', 'vue',
  },
})

-- lua_ls: stop it complaining about the global `vim` while editing this config
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim', 'MiniIcons' } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

-- Enable only servers whose binary is actually in PATH -- otherwise Neovim
-- throws an error every time a file is opened on a machine where that server
-- is not installed. Matters for a config shared between Linux, macOS, Windows.
-- blink.cmp advertises more than Neovim's defaults (snippet support, resolve
-- support, label details). This has to be registered BEFORE the servers start,
-- or they answer as if the client were less capable than it is.
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(nil, true),
})

local missing = {}
for name, bin in pairs(servers) do
  if vim.fn.executable(bin) == 1 then
    vim.lsp.enable(name)
  else
    missing[#missing + 1] = bin
  end
end

-- `:checkhealth` will not tell you a server was skipped, so make it inspectable.
table.sort(missing)
vim.api.nvim_create_user_command('LspMissing', function()
  if #missing == 0 then
    vim.notify('All configured LSP servers are installed.')
  else
    vim.notify('Not in PATH, so skipped:\n  ' .. table.concat(missing, '\n  '))
  end
end, { desc = 'List configured LSP servers that are not installed' })

-- --- completion ------------------------------------------------------------
-- Handled entirely by blink.cmp (configured in lua/plugins.lua). Nothing to do
-- here, and deliberately so:
--
--   * `vim.lsp.completion.enable()` is NOT called. Running it alongside blink
--     would mean two engines answering the same keystrokes and two menus.
--   * `completeopt` is not tuned either -- blink draws its own window and does
--     not go through Vim's popup menu, so `pumheight` and friends no longer
--     apply to it. They still govern `<C-n>` keyword completion, so the values
--     in options.lua stay.
--   * The old trick of appending letters to the server's `triggerCharacters`
--     is gone. It existed because native autotrigger fires only on characters
--     the server declares -- PHP is full of `$` and `->` so it felt automatic,
--     TypeScript only fires after `.` so it felt dead. blink decides on its
--     own when to show, per keystroke, regardless of what the server declares.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
  callback = function(ev)
    -- `gd` is not a default; grn/gra/grr/gri/grt/gO/K already are (see below)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition,
      { buffer = ev.data.buf, desc = 'LSP: go to definition' })
  end,
})

-- --- snippets --------------------------------------------------------------
-- No keymaps here any more. <Tab> / <S-Tab> / <CR> / <C-e> are owned by
-- blink.cmp's `keymap` table in lua/plugins.lua, which keeps them doing what
-- they did before: <Tab> walks the list, then jumps snippet placeholders, then
-- falls through to a literal Tab. Defining them in both places would mean
-- whichever loads last silently wins.
--
-- The snippet engine itself is unchanged -- blink is set to `preset = 'default'`,
-- which is Neovim's own `vim.snippet`. friendly-snippets is what is new: a
-- library of ready-made snippets that native completion could never surface,
-- because it only ever showed items the language server sent.

-- --- diagnostics ("error lens" without a plugin) ---------------------------
-- `virtual_text` prints the message at the end of the offending line -- that
-- is exactly what the VS Code Error Lens extension does, and it is built in.
--
-- `virtual_lines` is deliberately OFF. It renders the message again on its own
-- line below, connected by a └── guide, which on the cursor line means reading
-- the same error twice. Turn it on with `virtual_lines = { current_line = true }`
-- if you ever hit type errors too long to fit at the end of a line.
local sev = vim.diagnostic.severity

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false, -- do not re-lint on every keystroke
  virtual_text = {
    spacing = 2,
    prefix = vim.g.have_nerd_font and '●' or '>',
    source = 'if_many',
  },
  virtual_lines = false,
  signs = vim.g.have_nerd_font and {
    text = {
      [sev.ERROR] = '', [sev.WARN] = '', [sev.INFO] = '', [sev.HINT] = '',
    },
  } or true,
  float = { border = 'rounded', source = true },
})

-- Inline messages in the way while reading dense code? Toggle them off.
vim.keymap.set('n', '<leader>ud', function()
  local shown = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not shown and { spacing = 2, prefix = '●' } or false })
  vim.notify('inline diagnostics: ' .. (not shown and 'on' or 'off'))
end, { desc = 'UI: toggle inline diagnostics' })

-- Neovim 0.11+ defaults that do NOT need to be defined here:
--   K    hover              grn  rename           gra  code action
--   grr  references         gri  implementation   grt  type definition
--   gO   document symbols   ]d / [d  next/prev diagnostic
--   <C-s> (insert) signature help
