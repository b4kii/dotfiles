-- ===========================================================================
--  autocmds.lua
-- ===========================================================================

-- Your highlight_yank augroup. `vim.highlight` is deprecated since 0.11; the
-- replacement is `vim.hl`.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  desc = 'Highlight yanked text',
  callback = function()
    vim.hl.on_yank({ higroup = 'IncSearch', timeout = 150 })
  end,
})

-- Indent width per language.
--
-- The global setting (4 columns, hard tabs) comes from your init.vim and stays
-- the default. But two levels of hard tabs in an HTML file render 8 columns
-- wide, which is why nesting looked absurd. These are the widths the
-- respective communities and prettier actually use, so formatting with
-- <leader>cf no longer fights the editor.
local indent_width = {
  [2] = {
    'html', 'htmldjango', 'css', 'scss', 'less', 'javascript', 'typescript',
    'javascriptreact', 'typescriptreact', 'vue', 'svelte',
    'json', 'jsonc', 'yaml', 'lua', 'markdown', 'xml',
  },
  [4] = { 'php', 'python', 'sh', 'bash', 'c', 'cpp', 'java', 'rust', 'go' },
}

local width_for = {}
for width, fts in pairs(indent_width) do
  for _, ft in ipairs(fts) do width_for[ft] = width end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('indent_width', { clear = true }),
  desc = 'Per-language indent width',
  callback = function(args)
    local w = width_for[args.match]
    if not w then return end
    vim.bo[args.buf].shiftwidth = w
    vim.bo[args.buf].softtabstop = w
    vim.bo[args.buf].tabstop = w
    -- Spaces, not tabs, for everything listed here. `go` is the one language
    -- above that genuinely wants tabs, so it keeps them.
    vim.bo[args.buf].expandtab = args.match ~= 'go'
  end,
})

-- Neovim's php ftplugin sets commentstring to `/* %s */`, so `gcc` wraps a
-- single line in a block comment. `//` is what PHP code actually uses.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('commentstring_overrides', { clear = true }),
  pattern = { 'php' },
  desc = 'Use // for line comments instead of /* */',
  callback = function()
    vim.bo.commentstring = '// %s'
  end,
})


-- Sesje per folder, jak "otworz folder" w VS Code.
--
--   nvim / nvim . / nvim <folder>  -> wracaja pliki, splity i taby z ostatniego
--                                     razu w tym folderze, a przy wyjsciu
--                                     sesja zapisuje sie od nowa
--   nvim plik.php                  -> pojedynczy plik: sesji nie czyta i nie
--                                     nadpisuje (tak otwiera yazi po Enter)
--
-- Jeden plik na folder w stdpath('state')/sessions. :SessionForget kasuje
-- sesje biezacego folderu i wylacza zapis do konca tej sesji nvim.
local session_dir = vim.fs.joinpath(vim.fn.stdpath('state'), 'sessions')
local session_group = vim.api.nvim_create_augroup('folder_session', { clear = true })
local folder -- ustawiane tylko w trybie folderu; nil = nic nie zapisujemy

local function session_file(dir)
  local key = vim.fs.normalize(vim.fn.fnamemodify(dir, ':p')):gsub('/$', '')
  if vim.fn.has('win32') == 1 then key = key:lower() end -- W:\ i w:\ to ten sam folder
  return vim.fs.joinpath(session_dir, (key:gsub('[/:]', '%%')) .. '.vim')
end

vim.api.nvim_create_autocmd('VimEnter', {
  group = session_group,
  -- nested: przywrocone bufory musza dostac FileType, inaczej nie ma
  -- treesittera ani LSP, dopoki nie zrobisz :e
  nested = true,
  desc = 'Restore the session of the folder nvim was opened in',
  callback = function()
    if #vim.api.nvim_list_uis() == 0 then return end -- skrypty --headless
    -- `cmd | nvim`: tekst ze stdin, nie folder
    local first = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
    if vim.api.nvim_buf_get_name(0) == '' and (first ~= '' or vim.api.nvim_buf_line_count(0) > 1) then
      return
    end

    local argv = vim.fn.argv()
    -- oil przejmuje katalog jeszcze przed VimEnter i podmienia argument
    -- `.` na `oil:///...`, wiec folder bierzemy od niego
    local dir = argv[1]
    if dir and vim.bo.filetype == 'oil' then dir = require('oil').get_current_dir() end
    if #argv == 0 then
      folder = vim.fn.getcwd()
    elseif #argv == 1 and dir and vim.fn.isdirectory(dir) == 1 then
      folder = vim.fn.fnamemodify(dir, ':p')
      vim.cmd.cd(vim.fn.fnameescape(folder))
    else
      -- Pliki z argumentow (Enter w yazi): sesji nie wczytujemy, bo zaslonilaby
      -- plik, o ktory prosiles, ale przy wyjsciu zapisujemy ja dla biezacego
      -- folderu. Poza gitem: commit/rebase otwiera plik z .git\ i nadpisalby
      -- sesje projektu samym COMMIT_EDITMSG.
      if vim.o.diff then return end
      for _, a in ipairs(argv) do
        if a:find('[/\\]%.git[/\\]') or a:find('^%.git[/\\]') then return end
      end
      folder = vim.fn.getcwd()
      return
    end

    -- Po :restart Neovim przywraca wlasna sesje; wystarczy dalej zapisywac.
    if vim.v.startreason ~= 'normal' then return end

    local file = session_file(folder)
    if not vim.uv.fs_stat(file) then return end
    local start = vim.api.nvim_get_current_buf()
    vim.cmd('silent! source ' .. vim.fn.fnameescape(file))
    -- `nvim .` zostawia po sobie bufor oil z katalogiem; sesja go nie zamyka
    if vim.api.nvim_buf_is_valid(start) and #vim.fn.win_findbuf(start) == 0 then
      pcall(vim.api.nvim_buf_delete, start, {})
    end
  end,
})

vim.api.nvim_create_autocmd('VimLeavePre', {
  group = session_group,
  desc = 'Save the session of the current folder',
  callback = function()
    if not folder then return end

    -- Okna pomocnicze (Trouble, quickfix, terminal, floaty) wrocilyby jako
    -- puste panele. Oil zostaje -- to zwykly katalog, wraca normalnie.
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_win_get_config(win).relative ~= ''
        or (vim.bo[buf].buftype ~= '' and vim.bo[buf].filetype ~= 'oil') then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end

    -- Nic nie bylo otwarte (np. nvim i od razu :q) -> zostaw poprzednia sesje.
    local has_file = vim.iter(vim.api.nvim_list_bufs()):any(function(b)
      return vim.bo[b].buflisted and vim.bo[b].buftype == '' and vim.api.nvim_buf_get_name(b) ~= ''
    end)
    if not has_file then return end

    vim.fn.mkdir(session_dir, 'p')
    local keep = vim.o.sessionoptions
    vim.o.sessionoptions = 'buffers,curdir,tabpages,winsize'
    vim.cmd('mksession! ' .. vim.fn.fnameescape(session_file(folder)))
    vim.o.sessionoptions = keep
  end,
})

vim.api.nvim_create_user_command('SessionForget', function()
  if folder then os.remove(session_file(folder)) end
  folder = nil
  vim.notify('Sesja tego folderu usunieta, zapis wylaczony do wyjscia.')
end, { desc = 'Delete the session of the current folder and stop saving it' })




-- UNC
-- Sciezki sieciowe (\\serwer\udzial\...) zamiast zmapowanej litery psuja oil
-- ("attempt to index local 'drive'") i LSP ("UriError ... two slash
-- characters") -- oba chca litery dysku. Niewazne, skad sciezka przyszla
-- (yazi, LSP, Eksplorator): jesli udzial jest zmapowany, dostaje litere.
if vim.fn.has('win32') == 1 then
  local drives -- '\\serwer\udzial' (male litery) -> 'W:'; liczone przy pierwszej potrzebie

  local function mapped_drives()
    if drives then return drives end
    drives = {}
    -- zmapowane dyski z rejestru: bez dotykania sieci, wiec nie zawiesi sie
    -- na niedostepnym serwerze
    local letter
    for _, line in ipairs(vim.fn.systemlist({ 'reg', 'query', 'HKCU\\Network', '/s', '/v', 'RemotePath' })) do
      local l = line:match('\\Network\\(%a)%s*$')
      if l then letter = l:upper() .. ':' end
      local unc = line:match('RemotePath%s+REG_SZ%s+(\\\\.-)%s*$')
      if unc and letter then drives[unc:gsub('\\$', ''):lower()] = letter end
    end
    return drives
  end

  local function to_drive(path)
    if not path:match('^[\\/][\\/][^\\/]') then return nil end
    local p = path:gsub('/', '\\')
    for unc, letter in pairs(mapped_drives()) do
      local head = p:sub(1, #unc):lower()
      if head == unc and (#p == #unc or p:sub(#unc + 1, #unc + 1) == '\\') then
        return letter .. (p:sub(#unc + 1) ~= '' and p:sub(#unc + 1) or '\\')
      end
    end
  end

  local function fix_buf(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    -- oil robi z \\serwer\udzial adres oil:///serwer/udzial; normalnie pierwszy
    -- czlon to litera dysku (oil:///W/...), wiec dluzszy = sciezka sieciowa
    local oil_path = name:match('^oil:///+(.+)$')
    if oil_path then
      if oil_path:match('^%a/') or oil_path:match('^%a$') then return end
      local fixed = to_drive('\\\\' .. oil_path)
      if fixed then
        pcall(vim.api.nvim_buf_set_name, buf, 'oil:///' .. fixed:gsub(':', '', 1):gsub('\\', '/'))
      end
      return
    end
    local fixed = to_drive(name)
    if fixed then pcall(vim.api.nvim_buf_set_name, buf, fixed) end
  end

  local unc_group = vim.api.nvim_create_augroup('unc_to_drive', { clear = true })
  vim.api.nvim_create_autocmd('BufNew', {
    group = unc_group,
    desc = 'Open \\\\server\\share paths through the mapped drive letter',
    callback = function(args) fix_buf(args.buf) end,
  })

  -- pliki z linii polecen powstaja, zanim ten plik sie wczyta -- poprawiamy je tu
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do fix_buf(buf) end
  local cwd = to_drive(vim.fn.getcwd())
  if cwd then vim.cmd.cd(vim.fn.fnameescape(cwd)) end
end
