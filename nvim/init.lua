-- =========================
-- LEADER
-- musi byc przed pluginami i mappingami
-- =========================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

local function notify_error(name, err)
  vim.schedule(function()
    vim.notify(name .. " error: " .. tostring(err), vim.log.levels.ERROR)
  end)
end

local function safe_setup(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    notify_error(name, err)
  end
end

local function current_file_is_md()
  local name = vim.api.nvim_buf_get_name(0)

  if name == "" then
    return false
  end

  return vim.fn.fnamemodify(name, ":e"):lower() == "md"
end

local function markdown_only(name, fn)
  return function(...)
    if not current_file_is_md() then
      vim.notify((name or "This action") .. " works only in .md files", vim.log.levels.INFO)
      return
    end

    return fn(...)
  end
end

-- =========================
-- PLUGINS (vim-plug)
-- =========================
safe_setup("vim-plug", function()
  vim.cmd([[
call plug#begin()

Plug 'stevearc/oil.nvim'
Plug 'bngarren/checkmate.nvim'

" Telescope
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.8' }

" UI
Plug 'nvim-lualine/lualine.nvim'

" Git
Plug 'lewis6991/gitsigns.nvim'

" Commenting
Plug 'numToStr/Comment.nvim'

call plug#end()
]])
end)

-- =========================
-- BASIC OPTIONS
-- =========================
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 10
vim.opt.backspace = { "indent", "eol", "start" }

vim.opt.encoding = "utf-8"
vim.opt.termguicolors = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
-- vim.opt.expandtab = true -- odkomentuj, jesli chcesz spacje zamiast tabow

vim.opt.wildmenu = true
vim.opt.incsearch = true

vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.undofile = false

vim.opt.guicursor = "v-i:block"

-- Checkmate i custom worklog sa celowo ograniczone do realnych plikow .md.
-- Nie wymuszamy markdown filetype dla plikow bez rozszerzenia.
-- =========================
-- MAPPINGS
-- =========================
map("n", "<Space>", "<Nop>", { silent = true, desc = "Disable Space" })

map("n", "Y", "y$", { desc = "Yank to end of line" })

map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })

map("n", "zj", "o<Esc>k", { desc = "Insert empty line below" })
map("n", "zk", "O<Esc>j", { desc = "Insert empty line above" })

map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up centered" })

map("n", "<M-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<M-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>c", "<cmd>bdelete<CR>", { desc = "Close buffer" })
map("n", "<leader>c!", "<cmd>bdelete!<CR>", { desc = "Force close buffer" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "<leader>rr", function()
  local config_file = vim.env.MYVIMRC

  if not config_file or config_file == "" then
    config_file = vim.fn.stdpath("config") .. "/init.lua"
  end

  vim.cmd("source " .. vim.fn.fnameescape(config_file))
  vim.notify("Reloaded Neovim config: " .. config_file, vim.log.levels.INFO)
end, {
  desc = "Reload Neovim config",
})

-- =========================
-- HIGHLIGHT YANK
-- =========================
local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = yank_group,
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 150,
    })
  end,
})

-- =========================
-- TODO SECTIONS / WORKLOG
-- custom logika zamiast Checkmate checked/smart toggle
--
-- Jesli kursor jest w sekcji dnia "# dd-mm-yyyy", wszystkie operacje TODO
-- dzialaja tylko w obrebie tego dnia i uzywaja podsekcji:
-- ### TODO / ### IN PROGRESS / ### ARCHIVE
--
-- Poza sekcja dnia logika nadal dziala globalnie na:
-- ## TODO / ## IN PROGRESS / ## ARCHIVE
-- =========================
local TODO_SECTION = "## TODO"
local TODO_IN_PROGRESS_SECTION = "## IN PROGRESS"
local TODO_ARCHIVE_SECTION = "## ARCHIVE"

local DAY_TODO_SECTION = "### TODO"
local DAY_IN_PROGRESS_SECTION = "### IN PROGRESS"
local DAY_ARCHIVE_SECTION = "### ARCHIVE"

local DAY_HEADING_PATTERN = "^#%s+%d%d%-%d%d%-%d%d%d%d%s*$"
local DAY_SEPARATOR = "+---------------+"

local function refresh_checkmate_visuals()
  pcall(vim.cmd, "redraw!")
end

local function today_heading()
  return "# " .. os.date("%d-%m-%Y")
end

local function is_day_heading(line)
  return vim.trim(line or ""):match(DAY_HEADING_PATTERN) ~= nil
end

local function is_heading(line)
  return line:match("^#+%s+") ~= nil
end

local function is_section(line, section_name)
  return vim.trim(line) == section_name
end

local function raw_todo_prefix_and_rest(line)
  local prefix = line:match("^(%s*[-*+]%s+)")

  if prefix then
    return prefix, line:sub(#prefix + 1)
  end

  prefix = line:match("^(%s*%d+%.%s+)")

  if prefix then
    return prefix, line:sub(#prefix + 1)
  end

  return nil, nil
end

local function starts_with(text, prefix)
  return text:sub(1, #prefix) == prefix
end

local function clean_broken_utf8_marker_tail(text)
  text = text or ""

  -- To sprzata syf, ktory juz mogl sie zapisac przez stary pattern [○◉●].
  -- Lua patterny sa bajtowe, wiec [○◉●] potrafil zjesc tylko pierwszy bajt
  -- znaku UTF-8, zostawiajac w pliku np. <97><8b>, <97><89>, <97><8f>.
  local broken_tails = {
    string.char(0x97, 0x8b), -- reszta znaku ○
    string.char(0x97, 0x89), -- reszta znaku ◉
    string.char(0x97, 0x8f), -- reszta znaku ●
  }

  local changed = true

  while changed do
    changed = false

    for _, tail in ipairs(broken_tails) do
      if starts_with(text, tail) then
        text = text:sub(#tail + 1)
        changed = true
      end
    end

    local trimmed = text:gsub("^%s+", "")
    if trimmed ~= text then
      text = trimmed
      changed = true
    end
  end

  return text
end

local function now_worklog_time()
  return os.date("%H:%M")
end

local function now_worklog_datetime()
  return os.date("%d-%m-%Y %H:%M")
end

local function trim_text(text)
  return vim.trim(clean_broken_utf8_marker_tail(text or ""))
end

local function normalize_plain_todo_suffix(suffix)
  local text = trim_text(suffix)

  -- Zostawiamy trailing space przy pustym TODO, zeby od razu pisac po "- [ ] ".
  if text == "" then
    return " "
  end

  return " " .. text
end

local function parse_worklog_datetime(value)
  value = trim_text(value)

  local day, month, year, hour, minute = value:match("^(%d%d)%-(%d%d)%-(%d%d%d%d)%s+(%d%d):(%d%d)$")

  if day then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(minute),
      sec = 0,
    })
  end

  -- Kompatybilnosc z formatem z przykladu: 17-11-03 10:42.
  local short_year
  short_year, month, day, hour, minute = value:match("^(%d%d)%-(%d%d)%-(%d%d)%s+(%d%d):(%d%d)$")

  if short_year then
    local numeric_year = tonumber(short_year)

    if numeric_year < 70 then
      numeric_year = 2000 + numeric_year
    else
      numeric_year = 1900 + numeric_year
    end

    return os.time({
      year = numeric_year,
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(minute),
      sec = 0,
    })
  end

  return nil
end

local function format_worklog_duration(start_value, end_value)
  local start_ts = parse_worklog_datetime(start_value)
  local end_ts = parse_worklog_datetime(end_value)

  if not start_ts or not end_ts then
    return nil
  end

  local minutes = math.floor(os.difftime(end_ts, start_ts) / 60)

  if minutes < 0 then
    minutes = 0
  end

  local hours = math.floor(minutes / 60)
  local rest_minutes = minutes % 60

  if hours > 0 and rest_minutes > 0 then
    return tostring(hours) .. "h" .. tostring(rest_minutes) .. "m"
  end

  if hours > 0 then
    return tostring(hours) .. "h"
  end

  return tostring(rest_minutes) .. "m"
end

local function strip_worklog_time_metadata(text)
  text = trim_text(text)

  local metadata = {
    start = nil,
    end_time = nil,
    lasted = nil,
  }

  -- Stary prefix z poprzedniej wersji: [start: 14:32] albo [start: 14:32 end: 15:08].
  local old_start, old_end, rest = text:match("^%[start:%s*(%d%d:%d%d)%s+end:%s*(%d%d:%d%d)%]%s*(.*)$")

  if old_start then
    local today = os.date("%d-%m-%Y")
    metadata.start = today .. " " .. old_start
    metadata.end_time = today .. " " .. old_end
    text = trim_text(rest)
  else
    old_start, rest = text:match("^%[start:%s*(%d%d:%d%d)%]%s*(.*)$")

    if old_start then
      metadata.start = os.date("%d-%m-%Y") .. " " .. old_start
      text = trim_text(rest)
    end
  end

  local function remove_tag(pattern, target_key)
    text = text:gsub(pattern, function(value)
      if target_key == "end_time" then
        metadata.end_time = metadata.end_time or trim_text(value)
      else
        metadata[target_key] = metadata[target_key] or trim_text(value)
      end

      return ""
    end)
  end

  -- Wspieramy tez aliasy: @started(...), @archive(...) i @archived(...), ale zapisujemy juz jako @start/@end.
  remove_tag("%s*@start%(([^)]*)%)", "start")
  remove_tag("%s*@started%(([^)]*)%)", "start")
  remove_tag("%s*@end%(([^)]*)%)", "end_time")
  remove_tag("%s*@archive%(([^)]*)%)", "end_time")
  remove_tag("%s*@archived%(([^)]*)%)", "end_time")
  remove_tag("%s*@lasted%(([^)]*)%)", "lasted")

  -- Jezeli tagi byly w bloku:
  -- [ @start(...) @end(...) @lasted(...) ],
  -- po ich wyjeciu zostaje puste "[ ]", wiec je sprzatamy.
  text = text:gsub("%s*%[%s*%]%s*", " ")

  text = trim_text(text)

  return metadata.start, metadata.end_time, metadata.lasted, text
end

local function append_worklog_time_metadata(text, metadata_parts)
  text = trim_text(text)

  local suffix = table.concat(metadata_parts, " ")

  if suffix ~= "" then
    suffix = "[ " .. suffix .. " ]"
  end

  if text == "" then
    if suffix == "" then
      return " "
    end

    return " " .. suffix .. " "
  end

  if suffix == "" then
    return " " .. text
  end

  return " " .. text .. " " .. suffix
end

local function build_worklog_todo_suffix(suffix, state)
  local start_time, end_time, lasted, text = strip_worklog_time_metadata(suffix)

  if state == "unchecked" then
    return normalize_plain_todo_suffix(text)
  end

  if state == "in_progress" then
    start_time = start_time or now_worklog_datetime()

    return append_worklog_time_metadata(text, {
      "@start(" .. start_time .. ")",
    })
  end

  if state == "checked" then
    local now = now_worklog_datetime()
    start_time = start_time or now
    end_time = end_time or now
    lasted = format_worklog_duration(start_time, end_time) or lasted or "0m"

    return append_worklog_time_metadata(text, {
      "@start(" .. start_time .. ")",
      "@end(" .. end_time .. ")",
      "@lasted(" .. lasted .. ")",
    })
  end

  return normalize_plain_todo_suffix(text)
end

local function make_todo_line(state)
  local marks = {
    unchecked = " ",
    in_progress = "/",
    checked = "x",
  }

  local mark = marks[state] or " "

  return "- [" .. mark .. "]" .. build_worklog_todo_suffix("", state)
end

local function match_unicode_todo_marker(line)
  local prefix, rest = raw_todo_prefix_and_rest(line)

  if not prefix then
    return nil, nil, nil
  end

  local markers = {
    unchecked = "○",
    in_progress = "◉",
    checked = "●",
  }

  for state, marker in pairs(markers) do
    if starts_with(rest, marker) then
      return prefix, rest:sub(#marker + 1), state
    end
  end

  return nil, nil, nil
end

local function is_unchecked_todo(line)
  -- %s* po markerze lapie tez zepsute wpisy typu "- [ ]test".
  if line:match("^%s*[-*+]%s+%[%s%]%s*") ~= nil
    or line:match("^%s*%d+%.%s+%[%s%]%s*") ~= nil then
    return true
  end

  local _, _, state = match_unicode_todo_marker(line)
  return state == "unchecked"
end

local function is_in_progress_todo(line)
  if line:match("^%s*[-*+]%s+%[/%]%s*") ~= nil
    or line:match("^%s*%d+%.%s+%[/%]%s*") ~= nil then
    return true
  end

  local _, _, state = match_unicode_todo_marker(line)
  return state == "in_progress"
end

local function is_checked_todo(line)
  if line:match("^%s*[-*+]%s+%[[xXaA]%]%s*") ~= nil
    or line:match("^%s*%d+%.%s+%[[xXaA]%]%s*") ~= nil then
    return true
  end

  local _, _, state = match_unicode_todo_marker(line)
  return state == "checked"
end

local function get_todo_state(line)
  if is_unchecked_todo(line) then
    return "unchecked"
  end

  if is_in_progress_todo(line) then
    return "in_progress"
  end

  if is_checked_todo(line) then
    return "checked"
  end

  return nil
end

local function set_todo_state(line, state)
  local marks = {
    unchecked = " ",
    in_progress = "/",
    checked = "x",
  }

  local mark = marks[state]
  if not mark then
    return line
  end

  local prefix, suffix = line:match("^(%s*[-*+]%s+)%[.-%](.*)$")

  if not prefix then
    prefix, suffix = line:match("^(%s*%d+%.%s+)%[.-%](.*)$")
  end

  if not prefix then
    prefix, suffix = match_unicode_todo_marker(line)
  end

  if prefix then
    return prefix .. "[" .. mark .. "]" .. build_worklog_todo_suffix(suffix, state)
  end

  return line
end

local function remove_todo_marker(line)
  local prefix, suffix = line:match("^(%s*[-*+]%s+)%[.-%]%s*(.*)$")

  if not prefix then
    prefix, suffix = line:match("^(%s*%d+%.%s+)%[.-%]%s*(.*)$")
  end

  if not prefix then
    prefix, suffix = match_unicode_todo_marker(line)
  end

  if prefix then
    local _, _, _, text = strip_worklog_time_metadata(suffix)
    return prefix .. text
  end

  return line
end

local function append_line(output, line)
  table.insert(output, line)
end

local function append_blank(output)
  if output[#output] ~= "" then
    table.insert(output, "")
  end
end

local function trim_trailing_blank_lines(lines)
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
end

local function find_section(lines, section_name, start_index, end_index)
  start_index = start_index or 1
  end_index = end_index or #lines

  for i = start_index, end_index do
    if is_section(lines[i], section_name) then
      return i
    end
  end

  return nil
end

local function copy_lines_range(lines, start_index, end_index)
  local output = {}

  for i = start_index, end_index do
    table.insert(output, lines[i])
  end

  return output
end

local function find_day_end(lines, day_start)
  for i = day_start + 1, #lines do
    -- Kolejne "# ..." zaczyna nowy dzien / nowa sekcje top-level.
    -- Jezeli tuz nad kolejnym dniem jest separator, zostawiamy go przy kolejnym dniu,
    -- a nie jako ostatnia linie poprzedniego dnia.
    if lines[i]:match("^#%s+") then
      if i > day_start + 1 and vim.trim(lines[i - 1] or "") == DAY_SEPARATOR then
        return i - 2
      end

      return i - 1
    end
  end

  return #lines
end

local function day_scope_from_heading(lines, day_start)
  return {
    start_line = day_start,
    end_line = find_day_end(lines, day_start),
    todo = DAY_TODO_SECTION,
    in_progress = DAY_IN_PROGRESS_SECTION,
    archive = DAY_ARCHIVE_SECTION,
    daily = true,
  }
end

local function next_nonblank_index(lines, start_index)
  for i = start_index, #lines do
    if vim.trim(lines[i] or "") ~= "" then
      return i
    end
  end

  return nil
end

local function previous_nonblank_index(lines, start_index)
  for i = start_index, 1, -1 do
    if vim.trim(lines[i] or "") ~= "" then
      return i
    end
  end

  return nil
end

local function day_heading_near_separator(lines, cursor_line)
  -- Separator --------- jest wizualnie czescia dnia stojacego POD nim.
  -- Bez tego <leader>jn odpalone na separatorze laduje w globalnym ## TODO.
  if vim.trim(lines[cursor_line] or "") == DAY_SEPARATOR then
    local next_index = next_nonblank_index(lines, cursor_line + 1)

    if next_index and is_day_heading(lines[next_index]) then
      return next_index
    end
  end

  -- Dodatkowe zabezpieczenie: jezeli cos przypadkiem wpadlo miedzy separator
  -- i date, traktujemy ten obszar jako nalezacy do dnia pod spodem.
  local previous_index = previous_nonblank_index(lines, cursor_line - 1)
  local next_index = next_nonblank_index(lines, cursor_line + 1)

  if previous_index
    and next_index
    and vim.trim(lines[previous_index] or "") == DAY_SEPARATOR
    and is_day_heading(lines[next_index]) then
    return next_index
  end

  return nil
end

local function current_day_scope(lines)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  if #lines == 0 then
    return nil
  end

  cursor_line = math.min(cursor_line, #lines)

  local nearby_day_heading = day_heading_near_separator(lines, cursor_line)

  if nearby_day_heading then
    return day_scope_from_heading(lines, nearby_day_heading)
  end

  for i = cursor_line, 1, -1 do
    if is_day_heading(lines[i]) then
      return day_scope_from_heading(lines, i)
    end

    -- Jezeli idac w gore trafimy na inne "# ...", to znaczy,
    -- ze nie jestesmy w obrebie dnia typu "# dd-mm-yyyy".
    if lines[i]:match("^#%s+") then
      return nil
    end
  end

  return nil
end

local function current_todo_scope(lines)
  local day = current_day_scope(lines)

  if day then
    return day
  end

  return {
    start_line = 1,
    end_line = #lines,
    todo = TODO_SECTION,
    in_progress = TODO_IN_PROGRESS_SECTION,
    archive = TODO_ARCHIVE_SECTION,
    daily = false,
  }
end

local function insert_section_near_top(lines, section_name)
  if find_section(lines, section_name) then
    return lines
  end

  local output = {}

  if lines[1] and lines[1]:match("^#%s+") then
    append_line(output, lines[1])
    append_blank(output)
    append_line(output, section_name)
    append_blank(output)

    local start_index = 2
    while start_index <= #lines and lines[start_index] == "" do
      start_index = start_index + 1
    end

    for i = start_index, #lines do
      append_line(output, lines[i])
    end

    return output
  end

  append_line(output, section_name)
  append_blank(output)

  local start_index = 1
  while start_index <= #lines and lines[start_index] == "" do
    start_index = start_index + 1
  end

  for i = start_index, #lines do
    append_line(output, lines[i])
  end

  return output
end

local function insert_section_after_first_line(lines, section_name)
  if find_section(lines, section_name) then
    return lines
  end

  local output = {}

  if #lines == 0 then
    append_line(output, section_name)
    append_blank(output)
    return output
  end

  append_line(output, lines[1])
  append_blank(output)
  append_line(output, section_name)
  append_blank(output)

  local start_index = 2
  while start_index <= #lines and lines[start_index] == "" do
    start_index = start_index + 1
  end

  for i = start_index, #lines do
    append_line(output, lines[i])
  end

  return output
end

local function is_managed_todo_section(line, scope)
  return is_section(line, scope.todo)
    or is_section(line, scope.in_progress)
    or is_section(line, scope.archive)
end

local function append_todo_item(output, item)
  if type(item) == "table" then
    for _, line in ipairs(item) do
      append_line(output, line)
    end

    return
  end

  append_line(output, item)
end

local function make_todo_block(first_line, state, continuation_lines)
  local block = {
    set_todo_state(first_line, state),
  }

  for _, line in ipairs(continuation_lines or {}) do
    table.insert(block, line)
  end

  return block
end

local function collect_todo_continuation_lines(lines, start_index, scope)
  local continuation = {}
  local i = start_index

  while i <= #lines do
    local line = lines[i]

    if is_managed_todo_section(line, scope)
      or is_heading(line)
      or get_todo_state(line)
      or vim.trim(line or "") == "" then
      break
    end

    table.insert(continuation, line)
    i = i + 1
  end

  return continuation, i
end

local function insert_items_after_section(lines, section_name, items, create_strategy)
  local section_index = find_section(lines, section_name)
  local output = {}

  if not section_index then
    if create_strategy == "global_top" then
      lines = insert_section_near_top(lines, section_name)
      section_index = find_section(lines, section_name)
    elseif create_strategy == "after_first_line" then
      lines = insert_section_after_first_line(lines, section_name)
      section_index = find_section(lines, section_name)
    elseif #items == 0 then
      return lines
    else
      for _, line in ipairs(lines) do
        append_line(output, line)
      end

      trim_trailing_blank_lines(output)
      append_blank(output)
      append_line(output, section_name)
      append_blank(output)

      for _, item in ipairs(items) do
        append_todo_item(output, item)
      end

      return output
    end
  end

  if not section_index then
    return lines
  end

  local i = 1

  while i <= #lines do
    append_line(output, lines[i])

    if i == section_index then
      i = i + 1

      -- Usun wszystkie puste linie po naglowku sekcji.
      -- Ponizej dodajemy dokladnie jedna pusta linie tam, gdzie jest potrzebna.
      while i <= #lines and vim.trim(lines[i] or "") == "" do
        i = i + 1
      end

      if #items > 0 then
        -- Sekcja z taskami:
        -- ### TODO
        --
        -- - [ ] task
        append_blank(output)

        for _, item in ipairs(items) do
          append_todo_item(output, item)
        end

        -- Jedna pusta linia po taskach przed nastepna sekcja/trescia.
        if i <= #lines then
          append_blank(output)
        end
      else
        -- Sekcja pusta:
        -- ### TODO
        --
        -- ### IN PROGRESS
        --
        -- Zostawiamy dokladnie jedna pusta linie, jezeli dalej jest jakas tresc.
        if i <= #lines then
          append_blank(output)
        end
      end
    else
      i = i + 1
    end
  end

  return output
end

local function normalize_todo_lines(lines, scope)
  local unchecked = {}
  local in_progress = {}
  local archive = {}
  local rest = {}

  local inside_managed_section = false
  local i = 1

  while i <= #lines do
    local line = lines[i]

    if is_managed_todo_section(line, scope) then
      inside_managed_section = true
      table.insert(rest, line)
      i = i + 1
    elseif is_heading(line) then
      inside_managed_section = false
      table.insert(rest, line)
      i = i + 1
    else
      local state = get_todo_state(line)

      if state then
        local continuation_lines, next_index = collect_todo_continuation_lines(lines, i + 1, scope)

        if state == "unchecked" then
          table.insert(unchecked, make_todo_block(line, "unchecked", continuation_lines))
        elseif state == "in_progress" then
          table.insert(in_progress, make_todo_block(line, "in_progress", continuation_lines))
        elseif state == "checked" then
          table.insert(archive, make_todo_block(line, "checked", continuation_lines))
        end

        i = next_index
      elseif inside_managed_section and vim.trim(line or "") == "" then
        -- Puste wiersze w zarzadzanych sekcjach sa tylko formatowaniem.
        -- Usuwamy je, zeby po przeniesieniu taska nie zostawaly smieci.
        i = i + 1
      else
        table.insert(rest, line)
        i = i + 1
      end
    end
  end

  local output = rest

  local todo_create_strategy = scope.daily and "after_first_line" or "global_top"

  output = insert_items_after_section(output, scope.todo, unchecked, todo_create_strategy)
  output = insert_items_after_section(output, scope.in_progress, in_progress, false)
  output = insert_items_after_section(output, scope.archive, archive, false)

  trim_trailing_blank_lines(output)

  -- W dziennym worklogu zostawiamy jedna pusta linie po ARCHIVE,
  -- zeby separator nastepnego dnia nie przyklejal sie do sekcji.
  if scope.daily then
    append_blank(output)
  end

  return output
end

local function normalize_todo_sections()
  local view = vim.fn.winsaveview()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local scope = current_todo_scope(lines)

  local scoped_lines = copy_lines_range(lines, scope.start_line, scope.end_line)
  local output = normalize_todo_lines(scoped_lines, scope)

  vim.api.nvim_buf_set_lines(0, scope.start_line - 1, scope.end_line, false, output)
  vim.fn.winrestview(view)
  refresh_checkmate_visuals()

  local suffix = scope.daily and " in current day" or ""
  vim.notify("TODO sections updated" .. suffix, vim.log.levels.INFO)
end

local function get_target_range()
  local mode = vim.fn.mode()

  if mode == "v" or mode == "V" or mode == "\22" then
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")

    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    vim.cmd("normal! \27")
    return start_line, end_line
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  return line, line
end

local function transform_todos_in_range(transform)
  local start_line, end_line = get_target_range()
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local changed = false

  for i, line in ipairs(lines) do
    local state = get_todo_state(line)

    if state then
      local new_line = transform(line, state)

      if new_line and new_line ~= line then
        lines[i] = new_line
        changed = true
      end
    end
  end

  if not changed then
    vim.notify("No TODO found under cursor/selection", vim.log.levels.INFO)
    return
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
  normalize_todo_sections()
end

local function cycle_todo_next()
  local next_state = {
    unchecked = "in_progress",
    in_progress = "checked",
    checked = "unchecked",
  }

  transform_todos_in_range(function(line, state)
    return set_todo_state(line, next_state[state])
  end)
end

local function cycle_todo_previous()
  local previous_state = {
    unchecked = "checked",
    in_progress = "unchecked",
    checked = "in_progress",
  }

  transform_todos_in_range(function(line, state)
    return set_todo_state(line, previous_state[state])
  end)
end

local function mark_todo_archive()
  transform_todos_in_range(function(line)
    return set_todo_state(line, "checked")
  end)
end

local function mark_todo_unchecked()
  transform_todos_in_range(function(line)
    return set_todo_state(line, "unchecked")
  end)
end

local function mark_todo_in_progress()
  transform_todos_in_range(function(line)
    return set_todo_state(line, "in_progress")
  end)
end

local function remove_todo_under_cursor()
  transform_todos_in_range(function(line)
    return remove_todo_marker(line)
  end)
end

local function find_next_heading_index(lines, section_index)
  for i = section_index + 1, #lines do
    if is_heading(lines[i]) then
      return i
    end
  end

  return #lines + 1
end

local function insert_section_before_line(lines, section_name, before_index)
  local output = {}

  for i = 1, before_index - 1 do
    append_line(output, lines[i])
  end

  trim_trailing_blank_lines(output)
  append_blank(output)
  append_line(output, section_name)
  append_blank(output)

  for i = before_index, #lines do
    append_line(output, lines[i])
  end

  return output
end

local function append_section_at_bottom(lines, section_name)
  local output = {}

  for _, line in ipairs(lines) do
    append_line(output, line)
  end

  trim_trailing_blank_lines(output)
  append_blank(output)
  append_line(output, section_name)
  append_blank(output)

  return output
end

local function ensure_section_for_new_todo(lines, section_name, scope)
  if find_section(lines, section_name) then
    return lines
  end

  if section_name == scope.todo then
    if scope.daily then
      return insert_section_after_first_line(lines, section_name)
    end

    return insert_section_near_top(lines, section_name)
  end

  if section_name == scope.in_progress then
    local todo_index = find_section(lines, scope.todo)

    if todo_index then
      return insert_section_before_line(lines, section_name, find_next_heading_index(lines, todo_index))
    end

    local archive_index = find_section(lines, scope.archive)

    if archive_index then
      return insert_section_before_line(lines, section_name, archive_index)
    end
  end

  return append_section_at_bottom(lines, section_name)
end

local function create_todo_in_section(section_kind, state)
  local marks = {
    unchecked = " ",
    in_progress = "/",
    checked = "x",
  }

  local mark = marks[state]

  if not mark then
    vim.notify("Unknown TODO state: " .. tostring(state), vim.log.levels.ERROR)
    return
  end

  local all_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local scope = current_todo_scope(all_lines)
  local section_names = {
    todo = scope.todo,
    in_progress = scope.in_progress,
    archive = scope.archive,
  }

  local section_name = section_names[section_kind]

  if not section_name then
    vim.notify("Unknown TODO section kind: " .. tostring(section_kind), vim.log.levels.ERROR)
    return
  end

  local lines = copy_lines_range(all_lines, scope.start_line, scope.end_line)

  lines = ensure_section_for_new_todo(lines, section_name, scope)

  local section_index = find_section(lines, section_name)

  if not section_index then
    vim.notify("Could not create " .. section_name .. " section", vim.log.levels.ERROR)
    return
  end

  local insert_index = find_next_heading_index(lines, section_index)

  while insert_index > section_index + 1 and lines[insert_index - 1] == "" do
    insert_index = insert_index - 1
  end

  if insert_index == section_index + 1 then
    table.insert(lines, insert_index, "")
    insert_index = insert_index + 1
  end

  table.insert(lines, insert_index, make_todo_line(state))

  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  local absolute_insert_line = scope.start_line + insert_index - 1

  vim.api.nvim_buf_set_lines(bufnr, scope.start_line - 1, scope.end_line, false, lines)

  -- Wejdz w insert dokladnie na koncu linii: "- [ ] |" albo "- [/] |".
  -- Robimy to przez schedule, bo przy odpalaniu z mapowania Neovim czasem
  -- potrafi wrocic do normal mode, jesli startinsert poleci za wczesnie.
  refresh_checkmate_visuals()

  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(winid) then
      return
    end

    local line_text = vim.api.nvim_buf_get_lines(bufnr, absolute_insert_line - 1, absolute_insert_line, false)[1] or ""
    vim.api.nvim_win_set_cursor(winid, { absolute_insert_line, #line_text })
    vim.api.nvim_set_current_win(winid)
    vim.cmd("startinsert")
  end)
end

local function create_todo_in_todo_section()
  create_todo_in_section("todo", "unchecked")
end

local function create_todo_in_progress_section()
  create_todo_in_section("in_progress", "in_progress")
end

local function create_or_jump_today_worklog()
  local bufnr = vim.api.nvim_get_current_buf()
  local heading = today_heading()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local section_index = find_section(lines, heading)

  if not section_index then
    local block = {
      DAY_SEPARATOR,
      heading,
      "",
      DAY_TODO_SECTION,
      "",
      DAY_IN_PROGRESS_SECTION,
      "",
      DAY_ARCHIVE_SECTION,
      "",
    }

    local insert_index = 1

    -- Jezeli masz tytul pliku "# Worklog", nowy dzien wpada zaraz pod nim.
    -- Dzieki temu najnowszy dzien jest na gorze, nad starszymi dniami.
    if lines[1] and lines[1]:match("^#%s+") then
      insert_index = 2

      while insert_index <= #lines and lines[insert_index] == "" do
        insert_index = insert_index + 1
      end
    end

    for i = #block, 1, -1 do
      table.insert(lines, insert_index, block[i])
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    section_index = insert_index + 1

    vim.notify("Created worklog section: " .. heading, vim.log.levels.INFO)
  else
    vim.notify("Worklog section already exists: " .. heading, vim.log.levels.INFO)
  end

  local day_end = find_day_end(lines, section_index)
  local todo_index = find_section(lines, DAY_TODO_SECTION, section_index, day_end)
  local target_line = todo_index and (todo_index + 1) or (section_index + 1)

  if target_line > #lines then
    target_line = #lines
  end

  vim.api.nvim_win_set_cursor(0, { target_line, 0 })
end

vim.api.nvim_create_user_command("TodoNormalizeSections", markdown_only("TodoNormalizeSections", normalize_todo_sections), {
  desc = "Normalize TODO sections in current worklog day or globally",
})

vim.api.nvim_create_user_command("TodoMoveInProgress", markdown_only("TodoMoveInProgress", mark_todo_in_progress), {
  desc = "Mark TODO in progress and move to current IN PROGRESS section",
})

vim.api.nvim_create_user_command("TodoCreate", markdown_only("TodoCreate", create_todo_in_todo_section), {
  desc = "Create TODO in current TODO section",
})

vim.api.nvim_create_user_command("TodoCreateInProgress", markdown_only("TodoCreateInProgress", create_todo_in_progress_section), {
  desc = "Create TODO in current IN PROGRESS section",
})

vim.api.nvim_create_user_command("TodoToday", markdown_only("TodoToday", create_or_jump_today_worklog), {
  desc = "Create or jump to today's worklog section",
})

map({ "n", "v" }, "<leader>jj", markdown_only("Cycle TODO state", cycle_todo_next), {
  desc = "Cycle TODO state and normalize current section",
})

map({ "n", "v" }, "<leader>jJ", markdown_only("Cycle TODO state backwards", cycle_todo_previous), {
  desc = "Cycle TODO state backwards and normalize current section",
})

map({ "n", "v" }, "<leader>jd", markdown_only("Mark TODO archive", mark_todo_archive), {
  desc = "Mark TODO archive and move to current ARCHIVE",
})

map({ "n", "v" }, "<leader>ju", markdown_only("Mark TODO unchecked", mark_todo_unchecked), {
  desc = "Mark TODO unchecked and move to current TODO section",
})

map("n", "<leader>jn", markdown_only("Create TODO", create_todo_in_todo_section), {
  desc = "Create TODO in current TODO section",
})

map({ "n", "v" }, "<leader>jr", markdown_only("Remove TODO marker", remove_todo_under_cursor), {
  desc = "Remove TODO marker",
})

map("n", "<leader>ja", markdown_only("Normalize TODO sections", normalize_todo_sections), {
  desc = "Normalize current TODO sections",
})

map({ "n", "v" }, "<leader>ji", markdown_only("Mark TODO in progress", mark_todo_in_progress), {
  desc = "Mark TODO in progress and move to current IN PROGRESS",
})

map("n", "<leader>jD", markdown_only("Create/jump to today worklog", create_or_jump_today_worklog), {
  desc = "Create/jump to today's worklog date section",
})

map("n", "<leader>js", markdown_only("Create/jump to today worklog", create_or_jump_today_worklog), {
  desc = "Create/jump to today's worklog date section",
})


-- Custom metadata/tag management.
-- Nie uzywamy tutaj Checkmate `metadata select_value`, bo odpala picker
-- przez vim.ui.select. Jesli Telescope przejal vim.ui.select, dostajesz okno
-- Telescope, a wpisywany tekst jest filtrem wyboru, nie nowa wartoscia.
local WORKLOG_SYSTEM_METADATA = {
  start = true,
  started = true,
  ["end"] = true,
  archive = true,
  lasted = true,
}

local function metadata_clean_part(value)
  value = vim.trim(value or "")
  value = value:gsub("[()]", "")
  return value
end

local function metadata_prompt(prompt, default)
  default = default or ""
  local value = vim.fn.input(prompt, default)
  return metadata_clean_part(value)
end

local function find_metadata_at_col(line, col0)
  local col = col0 + 1
  local search_from = 1

  while true do
    local start_col, end_col, tag, value = line:find("@([%w_%-]+)%(([^)]*)%)", search_from)

    if not start_col then
      return nil
    end

    if col >= start_col and col <= end_col then
      return {
        start_col = start_col,
        end_col = end_col,
        tag = tag,
        value = value,
      }
    end

    search_from = end_col + 1
  end
end

local function find_first_metadata_for_tag(line, wanted_tag)
  local search_from = 1

  while true do
    local start_col, end_col, tag, value = line:find("@([%w_%-]+)%(([^)]*)%)", search_from)

    if not start_col then
      return nil
    end

    if tag == wanted_tag then
      return {
        start_col = start_col,
        end_col = end_col,
        tag = tag,
        value = value,
      }
    end

    search_from = end_col + 1
  end
end

local function current_line_metadata()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_number = cursor[1]
  local col0 = cursor[2]
  local line = vim.api.nvim_buf_get_lines(bufnr, line_number - 1, line_number, false)[1] or ""

  return bufnr, line_number, col0, line, find_metadata_at_col(line, col0)
end

local function set_current_line(bufnr, line_number, line)
  vim.api.nvim_buf_set_lines(bufnr, line_number - 1, line_number, false, { line })
  refresh_checkmate_visuals()
end

local function replace_metadata_segment(line, metadata, replacement)
  local before = line:sub(1, metadata.start_col - 1)
  local after = line:sub(metadata.end_col + 1)
  return before .. replacement .. after
end

local function append_or_replace_metadata(line, tag, value)
  local replacement = "@" .. tag .. "(" .. value .. ")"
  local existing = find_first_metadata_for_tag(line, tag)

  if existing then
    return replace_metadata_segment(line, existing, replacement)
  end

  if vim.trim(line) == "" then
    return replacement
  end

  return line:gsub("%s*$", "") .. " " .. replacement
end

local function metadata_add_or_update_current_line()
  local bufnr, line_number, _, line = current_line_metadata()
  local tag = metadata_prompt("Tag: ")

  if tag == "" then
    return
  end

  local value = metadata_prompt("Value for @" .. tag .. ": ")

  if value == "" then
    return
  end

  set_current_line(bufnr, line_number, append_or_replace_metadata(line, tag, value))
end

local function metadata_edit_value_under_cursor()
  local bufnr, line_number, _, line, metadata = current_line_metadata()

  if not metadata then
    vim.notify("Put cursor on @tag(value) first", vim.log.levels.INFO)
    return
  end

  local value = metadata_prompt("Value for @" .. metadata.tag .. ": ", metadata.value)

  if value == "" then
    return
  end

  local replacement = "@" .. metadata.tag .. "(" .. value .. ")"
  set_current_line(bufnr, line_number, replace_metadata_segment(line, metadata, replacement))
end

local function metadata_remove_current_line()
  local bufnr, line_number, _, line, metadata = current_line_metadata()

  if not metadata then
    local tag = metadata_prompt("Remove tag: ")

    if tag == "" then
      return
    end

    metadata = find_first_metadata_for_tag(line, tag)

    if not metadata then
      vim.notify("No @" .. tag .. " metadata on current line", vim.log.levels.INFO)
      return
    end
  end

  local new_line = replace_metadata_segment(line, metadata, "")
  new_line = new_line:gsub("%s+", " "):gsub("%s+$", "")
  set_current_line(bufnr, line_number, new_line)
end

local function metadata_toggle_current_line()
  local bufnr, line_number, _, line = current_line_metadata()
  local tag = metadata_prompt("Toggle tag: ")

  if tag == "" then
    return
  end

  local existing = find_first_metadata_for_tag(line, tag)

  if existing then
    local new_line = replace_metadata_segment(line, existing, "")
    new_line = new_line:gsub("%s+", " "):gsub("%s+$", "")
    set_current_line(bufnr, line_number, new_line)
    return
  end

  local value = metadata_prompt("Value for @" .. tag .. ": ")

  if value == "" then
    return
  end

  set_current_line(bufnr, line_number, append_or_replace_metadata(line, tag, value))
end

local function metadata_remove_user_metadata_current_line()
  local bufnr, line_number, _, line = current_line_metadata()
  local output = {}
  local last_end = 1
  local search_from = 1

  while true do
    local start_col, end_col, tag = line:find("%s*@([%w_%-]+)%([^)]*%)", search_from)

    if not start_col then
      table.insert(output, line:sub(last_end))
      break
    end

    table.insert(output, line:sub(last_end, start_col - 1))

    if WORKLOG_SYSTEM_METADATA[tag] then
      table.insert(output, line:sub(start_col, end_col))
    end

    last_end = end_col + 1
    search_from = end_col + 1
  end

  local new_line = table.concat(output):gsub("%s+", " "):gsub("%s+$", "")
  set_current_line(bufnr, line_number, new_line)
end

local function metadata_jump(next_direction)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line_number = cursor[1]
  local current_col = cursor[2] + 1
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  if next_direction then
    for line_number = current_line_number, line_count do
      local line = vim.api.nvim_buf_get_lines(bufnr, line_number - 1, line_number, false)[1] or ""
      local search_from = line_number == current_line_number and (current_col + 1) or 1
      local start_col = line:find("@[%w_%-]+%([^)]*%)", search_from)

      if start_col then
        vim.api.nvim_win_set_cursor(0, { line_number, start_col - 1 })
        return
      end
    end
  else
    local best_line = nil
    local best_col = nil

    for line_number = 1, current_line_number do
      local line = vim.api.nvim_buf_get_lines(bufnr, line_number - 1, line_number, false)[1] or ""
      local search_from = 1

      while true do
        local start_col, end_col = line:find("@[%w_%-]+%([^)]*%)", search_from)

        if not start_col then
          break
        end

        if line_number < current_line_number or start_col < current_col then
          best_line = line_number
          best_col = start_col
        end

        search_from = end_col + 1
      end
    end

    if best_line and best_col then
      vim.api.nvim_win_set_cursor(0, { best_line, best_col - 1 })
      return
    end
  end

  vim.notify("No metadata tag found", vim.log.levels.INFO)
end

map("n", "<leader>ka", markdown_only("Metadata: add/update tag", metadata_add_or_update_current_line), {
  desc = "Metadata: add/update tag on current line",
})

map("n", "<leader>kr", markdown_only("Metadata: remove tag", metadata_remove_current_line), {
  desc = "Metadata: remove tag under cursor/current line",
})

map("n", "<leader>kR", markdown_only("Metadata: remove user tags", metadata_remove_user_metadata_current_line), {
  desc = "Metadata: remove user tags, keep worklog time tags",
})

map("n", "<leader>kv", markdown_only("Metadata: edit value", metadata_edit_value_under_cursor), {
  desc = "Metadata: edit value under cursor",
})

map("n", "<leader>k]", markdown_only("Metadata: jump to next tag", function()
  metadata_jump(true)
end), {
  desc = "Metadata: jump to next tag",
})

map("n", "<leader>k[", markdown_only("Metadata: jump to previous tag", function()
  metadata_jump(false)
end), {
  desc = "Metadata: jump to previous tag",
})


-- =========================
-- OIL
-- =========================
local oil_ok, oil = pcall(require, "oil")

if oil_ok then
  safe_setup("oil.nvim", function()
    oil.setup()

    map("n", "<leader>e", "<cmd>Oil<CR>", {
      desc = "Open Oil",
    })
  end)
end

-- =========================
-- LUALINE
-- =========================
local lualine_ok, lualine = pcall(require, "lualine")

if lualine_ok then
  safe_setup("lualine.nvim", function()
    lualine.setup({
      options = {
        theme = "auto",
        globalstatus = true,
        icons_enabled = false,
        component_separators = "|",
        section_separators = "",
      },
    })
  end)
end

-- =========================
-- GITSIGNS
-- =========================
local gitsigns_ok, gitsigns = pcall(require, "gitsigns")

if gitsigns_ok then
  safe_setup("gitsigns.nvim", function()
    gitsigns.setup({
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    })

    map("n", "]g", "<cmd>Gitsigns next_hunk<CR>", {
      desc = "Next git hunk",
    })

    map("n", "[g", "<cmd>Gitsigns prev_hunk<CR>", {
      desc = "Previous git hunk",
    })

    map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", {
      desc = "Preview git hunk",
    })

    map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", {
      desc = "Git blame line",
    })

    map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", {
      desc = "Reset git hunk",
    })

    map("v", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", {
      desc = "Reset selected git hunk",
    })
  end)
end

-- =========================
-- COMMENT
-- =========================
local comment_ok, comment = pcall(require, "Comment")

if comment_ok then
  safe_setup("Comment.nvim", function()
    comment.setup()
  end)
end

-- =========================
-- TELESCOPE
-- =========================
local telescope_ok, telescope = pcall(require, "telescope")

if telescope_ok then
  safe_setup("telescope.nvim", function()
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<Esc>"] = actions.close,
          },
          n = {
            ["q"] = actions.close,
          },
        },
      },
    })

    local builtin = require("telescope.builtin")

    map("n", "<leader>ff", builtin.find_files, {
      desc = "Find files",
    })

    map("n", "<leader>fg", builtin.live_grep, {
      desc = "Live grep",
    })

    map("n", "<leader>fb", builtin.buffers, {
      desc = "Find buffers",
    })

    map("n", "<leader>fh", builtin.help_tags, {
      desc = "Find help",
    })

    map("n", "<leader>fr", builtin.oldfiles, {
      desc = "Recent files",
    })

    map("n", "<leader>fc", builtin.commands, {
      desc = "Find commands",
    })

    map("n", "<leader>fk", builtin.keymaps, {
      desc = "Find keymaps",
    })
  end)
end

-- =========================
-- CHECKMATE TODO
-- =========================
local checkmate_ok, checkmate = pcall(require, "checkmate")

if checkmate_ok then
  safe_setup("checkmate.nvim", function()
    checkmate.setup({
      enabled = true,
      notify = true,

      files = {
        "*.md",
      },

      default_list_marker = "-",

      -- Wylaczone, bo smart_toggle moze ruszac dzieci/rodzicow taska
      -- i powodowac efekt, jakby wiele pozycji naraz zmienialo stan.
      smart_toggle = {
        enabled = false,
      },

      -- Nie nadpisujemy style Checkmate: domyslne CheckedMainContent robi strikethrough.

      todo_states = {
        unchecked = {
          marker = "○",
          order = 1,
        },

        in_progress = {
          marker = "◉",
          markdown = "/",
          type = "incomplete",
          order = 2,
        },

        checked = {
          marker = "●",
          order = 3,
        },
      },

      -- Nie mapujemy tu <leader>j*, bo powyzej mamy wlasna logike:
      -- TODO -> IN PROGRESS -> ARCHIVE -> TODO.
      keys = {},

      list_continuation = {
        enabled = true,
        split_line = true,
      },
    })
  end)
end

-- =========================
-- SHORTCUTS SUMMARY
-- =========================
-- Space w    -> zapisz plik
-- Space c    -> zamknij buffer
-- Space c!   -> zamknij buffer na sile
-- Space h    -> usun highlight szukania
-- Space rr   -> przeladuj aktualny plik
-- Space e    -> Oil file explorer

-- Telescope:
-- Space f f  -> szukaj plikow
-- Space f g  -> szukaj tekstu w projekcie
-- Space f b  -> bufory
-- Space f h  -> help
-- Space f r  -> ostatnie pliki
-- Space f c  -> komendy
-- Space f k  -> keymapy

-- GitSigns:
-- ] g        -> nastepna zmiana git
-- [ g        -> poprzednia zmiana git
-- Space g p  -> podglad zmiany
-- Space g b  -> blame aktualnej linii
-- Space g r  -> cofnij zmiane/hunk

-- Comment:
-- g c c      -> zakomentuj/odkomentuj linie
-- g c        -> zakomentuj/odkomentuj zaznaczenie w visualu

-- Custom TODO / Worklog:
-- Space j D  -> dodaj/przejdz do dzisiejszej sekcji # dd-mm-yyyy z separatorem +---------------+
-- Space j s  -> to samo co Space j D
-- Space j n  -> dodaj nowe TODO w aktualnym dniu albo globalnym ## TODO
-- Space j j  -> TODO -> IN PROGRESS @start -> ARCHIVE/checked @start/@end/@lasted -> TODO w aktualnym dniu
-- Space j J  -> cykl wstecz w aktualnym dniu
-- Space j d  -> oznacz archive, dodaj @end/@lasted na koncu i przenies do ARCHIVE w aktualnym dniu
-- Space j u  -> odznacz i przenies do TODO w aktualnym dniu
-- Space j r  -> usun checkbox
-- Space j a  -> recznie odswiez sekcje aktualnego dnia
-- Space j i  -> oznacz jako in progress, dodaj @start na koncu i przenies do IN PROGRESS w aktualnym dniu
-- Space k a -> dodaj albo zaktualizuj @tag(value) na aktualnej linii
-- Space k r -> usun @tag(value) pod kursorem albo po nazwie taga
-- Space k R -> usun user tagi z linii, ale zostaw @start/@end/@lasted
-- Space k v -> edytuj value taga pod kursorem bez okna Telescope
-- Space k ] -> nastepny tag metadata
-- Space k [ -> poprzedni tag metadata

-- Komendy:
-- :TodoToday
-- :TodoCreate
-- :TodoNormalizeSections
-- :TodoMoveInProgress
-- :TodoCreateInProgress
