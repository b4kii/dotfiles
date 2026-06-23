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

-- Checkmate dziala tylko na markdownach, wiec pliki "todo"/"TODO"
-- bez rozszerzenia ustawiamy automatycznie jako markdown.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "todo", "TODO", "*.todo", "*.todo.md" },
  callback = function()
    vim.bo.filetype = "markdown"
  end,
})

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
-- TODO SECTIONS
-- custom logika zamiast Checkmate archive/smart toggle
-- =========================
local TODO_SECTION = "## TODO"
local TODO_IN_PROGRESS_SECTION = "## IN PROGRESS"
local TODO_ARCHIVE_SECTION = "## ARCHIVE"

local function refresh_checkmate_visuals()
  pcall(vim.cmd, "redraw!")
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

local function normalize_todo_suffix(suffix)
  suffix = clean_broken_utf8_marker_tail(suffix)

  -- Zostawiamy trailing space przy pustym TODO, zeby od razu pisac po "- [ ] ".
  if suffix == "" then
    return " "
  end

  return " " .. suffix
end

local function match_unicode_todo_marker(line)
  local prefix, rest = raw_todo_prefix_and_rest(line)

  if not prefix then
    return nil, nil, nil
  end

  local markers = {
    unchecked = "○",
    in_progress = "◉",
    done = "●",
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

local function is_done_todo(line)
  if line:match("^%s*[-*+]%s+%[[xX]%]%s*") ~= nil
    or line:match("^%s*%d+%.%s+%[[xX]%]%s*") ~= nil then
    return true
  end

  local _, _, state = match_unicode_todo_marker(line)
  return state == "done"
end

local function get_todo_state(line)
  if is_unchecked_todo(line) then
    return "unchecked"
  end

  if is_in_progress_todo(line) then
    return "in_progress"
  end

  if is_done_todo(line) then
    return "done"
  end

  return nil
end

local function set_todo_state(line, state)
  local marks = {
    unchecked = " ",
    in_progress = "/",
    done = "x",
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
    return prefix .. "[" .. mark .. "]" .. normalize_todo_suffix(suffix)
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
    return prefix .. clean_broken_utf8_marker_tail(suffix)
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

local function find_section(lines, section_name)
  for i, line in ipairs(lines) do
    if is_section(line, section_name) then
      return i
    end
  end

  return nil
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

local function insert_items_after_section(lines, section_name, items, create_near_top)
  if #items == 0 then
    if create_near_top then
      return insert_section_near_top(lines, section_name)
    end

    return lines
  end

  local section_index = find_section(lines, section_name)
  local output = {}

  if not section_index then
    if create_near_top then
      lines = insert_section_near_top(lines, section_name)
      section_index = find_section(lines, section_name)
    else
      for _, line in ipairs(lines) do
        append_line(output, line)
      end

      trim_trailing_blank_lines(output)
      append_blank(output)
      append_line(output, section_name)
      append_blank(output)

      for _, item in ipairs(items) do
        append_line(output, item)
      end

      return output
    end
  end

  local i = 1

  while i <= #lines do
    append_line(output, lines[i])

    if i == section_index then
      i = i + 1

      while i <= #lines and lines[i] == "" do
        i = i + 1
      end

      append_blank(output)

      for _, item in ipairs(items) do
        append_line(output, item)
      end

      if i <= #lines then
        append_blank(output)
      end
    else
      i = i + 1
    end
  end

  return output
end

local function normalize_todo_sections()
  local view = vim.fn.winsaveview()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local unchecked = {}
  local in_progress = {}
  local done = {}
  local rest = {}

  for _, line in ipairs(lines) do
    if is_unchecked_todo(line) then
      table.insert(unchecked, set_todo_state(line, "unchecked"))
    elseif is_in_progress_todo(line) then
      table.insert(in_progress, set_todo_state(line, "in_progress"))
    elseif is_done_todo(line) then
      table.insert(done, set_todo_state(line, "done"))
    else
      table.insert(rest, line)
    end
  end

  local output = rest

  output = insert_items_after_section(output, TODO_SECTION, unchecked, true)
  output = insert_items_after_section(output, TODO_IN_PROGRESS_SECTION, in_progress, false)
  output = insert_items_after_section(output, TODO_ARCHIVE_SECTION, done, false)

  trim_trailing_blank_lines(output)

  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  vim.fn.winrestview(view)
  refresh_checkmate_visuals()

  vim.notify("TODO sections updated", vim.log.levels.INFO)
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
    in_progress = "done",
    done = "unchecked",
  }

  transform_todos_in_range(function(line, state)
    return set_todo_state(line, next_state[state])
  end)
end

local function cycle_todo_previous()
  local previous_state = {
    unchecked = "done",
    in_progress = "unchecked",
    done = "in_progress",
  }

  transform_todos_in_range(function(line, state)
    return set_todo_state(line, previous_state[state])
  end)
end

local function mark_todo_done()
  transform_todos_in_range(function(line)
    return set_todo_state(line, "done")
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

local function ensure_section_for_new_todo(lines, section_name)
  if find_section(lines, section_name) then
    return lines
  end

  if section_name == TODO_SECTION then
    return insert_section_near_top(lines, section_name)
  end

  if section_name == TODO_IN_PROGRESS_SECTION then
    local todo_index = find_section(lines, TODO_SECTION)

    if todo_index then
      return insert_section_before_line(lines, section_name, find_next_heading_index(lines, todo_index))
    end

    local archive_index = find_section(lines, TODO_ARCHIVE_SECTION)

    if archive_index then
      return insert_section_before_line(lines, section_name, archive_index)
    end
  end

  return append_section_at_bottom(lines, section_name)
end

local function create_todo_in_section(section_name, state)
  local marks = {
    unchecked = " ",
    in_progress = "/",
    done = "x",
  }

  local mark = marks[state]

  if not mark then
    vim.notify("Unknown TODO state: " .. tostring(state), vim.log.levels.ERROR)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  lines = ensure_section_for_new_todo(lines, section_name)

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

  table.insert(lines, insert_index, "- [" .. mark .. "] ")

  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Wejdz w insert dokladnie na koncu linii: "- [ ] |" albo "- [/] |".
  -- Robimy to przez schedule, bo przy odpalaniu z mapowania Neovim czasem
  -- potrafi wrocic do normal mode, jesli startinsert poleci za wczesnie.
  refresh_checkmate_visuals()

  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(winid) then
      return
    end

    local line_text = vim.api.nvim_buf_get_lines(bufnr, insert_index - 1, insert_index, false)[1] or ""
    vim.api.nvim_win_set_cursor(winid, { insert_index, #line_text })
    vim.api.nvim_set_current_win(winid)
    vim.cmd("startinsert")
  end)
end

local function create_todo_in_todo_section()
  create_todo_in_section(TODO_SECTION, "unchecked")
end

local function create_todo_in_progress_section()
  create_todo_in_section(TODO_IN_PROGRESS_SECTION, "in_progress")
end

vim.api.nvim_create_user_command("TodoNormalizeSections", normalize_todo_sections, {
  desc = "Normalize TODO sections",
})

vim.api.nvim_create_user_command("TodoMoveInProgress", mark_todo_in_progress, {
  desc = "Mark TODO in progress and move to ## IN PROGRESS",
})

vim.api.nvim_create_user_command("TodoCreate", create_todo_in_todo_section, {
  desc = "Create TODO in ## TODO section",
})

vim.api.nvim_create_user_command("TodoCreateInProgress", create_todo_in_progress_section, {
  desc = "Create TODO in ## IN PROGRESS section",
})

map({ "n", "v" }, "<leader>nt", cycle_todo_next, {
  desc = "Cycle TODO state and normalize sections",
})

map({ "n", "v" }, "<leader>nT", cycle_todo_previous, {
  desc = "Cycle TODO state backwards and normalize sections",
})

map({ "n", "v" }, "<leader>nd", mark_todo_done, {
  desc = "Mark TODO done and move to archive",
})

map({ "n", "v" }, "<leader>nu", mark_todo_unchecked, {
  desc = "Mark TODO undone and move to TODO section",
})

map("n", "<leader>nn", create_todo_in_todo_section, {
  desc = "Create TODO in TODO section",
})

map({ "n", "v" }, "<leader>nr", remove_todo_under_cursor, {
  desc = "Remove TODO marker",
})

map("n", "<leader>na", normalize_todo_sections, {
  desc = "Normalize TODO sections",
})

map({ "n", "v" }, "<leader>ni", mark_todo_in_progress, {
  desc = "Mark TODO in progress and move to IN PROGRESS",
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
        "todo",
        "TODO",
        "todo.md",
        "TODO.md",
        "*.todo",
        "*.todo.md",
      },

      default_list_marker = "-",

      -- Wylaczone, bo smart_toggle moze ruszac dzieci/rodzicow taska
      -- i powodowac efekt, jakby wiele pozycji naraz zmienialo stan.
      smart_toggle = {
        enabled = false,
      },

      -- TODO i IN PROGRESS bez przekreslenia.
      -- DONE/ARCHIVE z przekresleniem tylko glownej linii,
      -- bez additional content, zeby nie przekreslalo wielu linii naraz.
      style = {
        CheckmateUncheckedMarker = { strikethrough = false },
        CheckmateUncheckedMainContent = { strikethrough = false },
        CheckmateUncheckedAdditionalContent = { strikethrough = false },

        CheckmateInProgressMarker = { strikethrough = false },
        CheckmateInProgressMainContent = { strikethrough = false },
        CheckmateInProgressAdditionalContent = { strikethrough = false },

        CheckmateCheckedMarker = { strikethrough = true },
        CheckmateCheckedMainContent = { strikethrough = true },
        CheckmateCheckedAdditionalContent = { strikethrough = false },
      },

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

      -- Nie mapujemy tu <leader>t*, bo powyzej mamy wlasna logike:
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

-- Custom TODO:
-- Space n n  -> dodaj nowe TODO w ## TODO i wejdz w insert
-- Space n t  -> TODO -> IN PROGRESS -> ARCHIVE -> TODO
-- Space n T  -> cykl wstecz
-- Space n d  -> oznacz done i przenies do ## ARCHIVE
-- Space n u  -> odznacz i przenies do ## TODO
-- Space n r  -> usun checkbox
-- Space n a  -> recznie odswiez sekcje
-- Space n i  -> oznacz jako in progress i przenies do ## IN PROGRESS

-- Komendy:
-- :TodoCreate
-- :TodoNormalizeSections
-- :TodoMoveInProgress
-- :TodoCreateInProgress
