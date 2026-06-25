local M = {}

local cfg = {}
local map = vim.keymap.set

local MARKERS = {
  unicode_unchecked = vim.fn.nr2char(0x25CB),
  unicode_in_progress = vim.fn.nr2char(0x25C9),
  unicode_done = vim.fn.nr2char(0x25CF),
}

local defaults = {
  notify = true,
  commands = true,
  mappings = true,

  -- By default this plugin intentionally works only in real Markdown files.
  filetypes = {
    markdown = true,
  },
  extensions = {
    md = true,
  },

  date_format = "%d-%m-%Y",
  datetime_format = "%d-%m-%Y %H:%M",
  day_heading_pattern = "^#%s+%d%d%-%d%d%-%d%d%d%d%s*$",
  day_separator = "---------",

  sections = {
    global = {
      todo = "## TODO",
      in_progress = "## IN PROGRESS",
      archive = "## ARCHIVE",
    },
    day = {
      todo = "### TODO",
      in_progress = "### IN PROGRESS",
      archive = "### ARCHIVE",
    },
  },

  keys = {
    today = "<leader>jD",
    today_alt = "<leader>js",
    create = "<leader>jn",
    cycle_next = "<leader>jt",
    cycle_next_alt = "<leader>jj",
    cycle_previous = "<leader>jT",
    cycle_previous_alt = "<leader>jJ",
    done = "<leader>jd",
    unchecked = "<leader>ju",
    remove_marker = "<leader>jr",
    normalize = "<leader>ja",
    in_progress = "<leader>ji",

    metadata_add_or_update = "<leader>ka",
    metadata_toggle = "<leader>kt",
    metadata_remove = "<leader>kr",
    metadata_remove_user = "<leader>kR",
    metadata_edit_value = "<leader>kv",
    metadata_next = "<leader>k]",
    metadata_previous = "<leader>k[",
  },

  checkmate = {
    enabled = true,
  },
}

local function deep_extend(...)
  return vim.tbl_deep_extend("force", ...)
end

local function notify(message, level)
  if cfg.notify == false then
    return
  end

  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO)
  end)
end

local function notify_error(name, err)
  notify(name .. " error: " .. tostring(err), vim.log.levels.ERROR)
end

local function safe_call(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    notify_error(name, err)
  end
  return ok
end

local function is_allowed_buffer()
  local ft = vim.bo.filetype

  if ft and cfg.filetypes and cfg.filetypes[ft] then
    return true
  end

  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return false
  end

  local ext = vim.fn.fnamemodify(name, ":e"):lower()
  return cfg.extensions and cfg.extensions[ext] == true
end

local function markdown_only(name, fn)
  return function(...)
    if not is_allowed_buffer() then
      notify((name or "This action") .. " works only in Markdown files")
      return
    end

    return fn(...)
  end
end

local function get_lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)
end

local function set_scope_lines(bufnr, scope, lines)
  vim.api.nvim_buf_set_lines(bufnr or 0, scope.start_line - 1, scope.end_line, false, lines)
end

local function refresh_visuals()
  pcall(vim.cmd, "redraw!")
end

local function starts_with(text, prefix)
  return text:sub(1, #prefix) == prefix
end

local function today_heading()
  return "# " .. os.date(cfg.date_format)
end

local function now_datetime()
  return os.date(cfg.datetime_format)
end

local function is_day_heading(line)
  return vim.trim(line or ""):match(cfg.day_heading_pattern) ~= nil
end

local function is_heading(line)
  return (line or ""):match("^#+%s+") ~= nil
end

local function is_section(line, section_name)
  return vim.trim(line or "") == section_name
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

local function clean_broken_utf8_marker_tail(text)
  text = text or ""

  local broken_tails = {
    string.char(0x97, 0x8b),
    string.char(0x97, 0x89),
    string.char(0x97, 0x8f),
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

local function trim_text(text)
  return vim.trim(clean_broken_utf8_marker_tail(text or ""))
end

local function normalize_plain_todo_suffix(suffix)
  local text = trim_text(suffix)

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

  local old_start, old_end, rest = text:match("^%[start:%s*(%d%d:%d%d)%s+end:%s*(%d%d:%d%d)%]%s*(.*)$")
  if old_start then
    local today = os.date(cfg.date_format)
    metadata.start = today .. " " .. old_start
    metadata.end_time = today .. " " .. old_end
    text = trim_text(rest)
  else
    old_start, rest = text:match("^%[start:%s*(%d%d:%d%d)%]%s*(.*)$")
    if old_start then
      metadata.start = os.date(cfg.date_format) .. " " .. old_start
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

  remove_tag("%s*@start%(([^)]*)%)", "start")
  remove_tag("%s*@started%(([^)]*)%)", "start")
  remove_tag("%s*@end%(([^)]*)%)", "end_time")
  remove_tag("%s*@done%(([^)]*)%)", "end_time")
  remove_tag("%s*@lasted%(([^)]*)%)", "lasted")

  text = trim_text(text)

  return metadata.start, metadata.end_time, metadata.lasted, text
end

local function append_worklog_time_metadata(text, metadata_parts)
  text = trim_text(text)

  local suffix = table.concat(metadata_parts, " ")

  if text == "" then
    if suffix == "" then
      return " "
    end

    return " " .. suffix
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
    start_time = start_time or now_datetime()

    return append_worklog_time_metadata(text, {
      "@start(" .. start_time .. ")",
    })
  end

  if state == "done" then
    local now = now_datetime()
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
    done = "x",
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
    unchecked = MARKERS.unicode_unchecked,
    in_progress = MARKERS.unicode_in_progress,
    done = MARKERS.unicode_done,
  }

  for state, marker in pairs(markers) do
    if starts_with(rest, marker) then
      return prefix, rest:sub(#marker + 1), state
    end
  end

  return nil, nil, nil
end

local function is_unchecked_todo(line)
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
    if lines[i]:match("^#%s+") then
      if i > day_start + 1 and vim.trim(lines[i - 1] or "") == cfg.day_separator then
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
    todo = cfg.sections.day.todo,
    in_progress = cfg.sections.day.in_progress,
    archive = cfg.sections.day.archive,
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
  if vim.trim(lines[cursor_line] or "") == cfg.day_separator then
    local next_index = next_nonblank_index(lines, cursor_line + 1)

    if next_index and is_day_heading(lines[next_index]) then
      return next_index
    end
  end

  local previous_index = previous_nonblank_index(lines, cursor_line - 1)
  local next_index = next_nonblank_index(lines, cursor_line + 1)

  if previous_index
    and next_index
    and vim.trim(lines[previous_index] or "") == cfg.day_separator
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
    todo = cfg.sections.global.todo,
    in_progress = cfg.sections.global.in_progress,
    archive = cfg.sections.global.archive,
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

local function insert_items_after_section(lines, section_name, items, create_strategy)
  if #items == 0 then
    if create_strategy == "global_top" then
      return insert_section_near_top(lines, section_name)
    end

    if create_strategy == "after_first_line" then
      return insert_section_after_first_line(lines, section_name)
    end

    return lines
  end

  local section_index = find_section(lines, section_name)
  local output = {}

  if not section_index then
    if create_strategy == "global_top" then
      lines = insert_section_near_top(lines, section_name)
      section_index = find_section(lines, section_name)
    elseif create_strategy == "after_first_line" then
      lines = insert_section_after_first_line(lines, section_name)
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

local function normalize_todo_lines(lines, scope)
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
  local todo_create_strategy = scope.daily and "after_first_line" or "global_top"

  output = insert_items_after_section(output, scope.todo, unchecked, todo_create_strategy)
  output = insert_items_after_section(output, scope.in_progress, in_progress, false)
  output = insert_items_after_section(output, scope.archive, done, false)

  trim_trailing_blank_lines(output)

  return output
end

function M.normalize()
  local view = vim.fn.winsaveview()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = get_lines(bufnr)
  local scope = current_todo_scope(lines)
  local scoped_lines = copy_lines_range(lines, scope.start_line, scope.end_line)
  local output = normalize_todo_lines(scoped_lines, scope)

  set_scope_lines(bufnr, scope, output)
  vim.fn.winrestview(view)
  refresh_visuals()

  local suffix = scope.daily and " in current day" or ""
  notify("TODO sections updated" .. suffix)
end

local function get_target_range()
  local mode = vim.fn.mode()

  if mode == "v" or mode == "V" or mode == "\22" then
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")

    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
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
    notify("No TODO found under cursor/selection")
    return
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
  M.normalize()
end

function M.cycle_next()
  local next_state = {
    unchecked = "in_progress",
    in_progress = "done",
    done = "unchecked",
  }

  transform_todos_in_range(function(line, state)
    return set_todo_state(line, next_state[state])
  end)
end

function M.cycle_previous()
  local previous_state = {
    unchecked = "done",
    in_progress = "unchecked",
    done = "in_progress",
  }

  transform_todos_in_range(function(line, state)
    return set_todo_state(line, previous_state[state])
  end)
end

function M.mark_done()
  transform_todos_in_range(function(line)
    return set_todo_state(line, "done")
  end)
end

function M.mark_unchecked()
  transform_todos_in_range(function(line)
    return set_todo_state(line, "unchecked")
  end)
end

function M.mark_in_progress()
  transform_todos_in_range(function(line)
    return set_todo_state(line, "in_progress")
  end)
end

function M.remove_marker()
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
    done = "x",
  }

  local mark = marks[state]
  if not mark then
    notify("Unknown TODO state: " .. tostring(state), vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  local all_lines = get_lines(bufnr)
  local scope = current_todo_scope(all_lines)
  local section_names = {
    todo = scope.todo,
    in_progress = scope.in_progress,
    archive = scope.archive,
  }

  local section_name = section_names[section_kind]
  if not section_name then
    notify("Unknown TODO section kind: " .. tostring(section_kind), vim.log.levels.ERROR)
    return
  end

  local lines = copy_lines_range(all_lines, scope.start_line, scope.end_line)
  lines = ensure_section_for_new_todo(lines, section_name, scope)

  local section_index = find_section(lines, section_name)
  if not section_index then
    notify("Could not create " .. section_name .. " section", vim.log.levels.ERROR)
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

  local absolute_insert_line = scope.start_line + insert_index - 1
  set_scope_lines(bufnr, scope, lines)
  refresh_visuals()

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

function M.create_todo()
  create_todo_in_section("todo", "unchecked")
end

function M.create_in_progress()
  create_todo_in_section("in_progress", "in_progress")
end

function M.today()
  local bufnr = vim.api.nvim_get_current_buf()
  local heading = today_heading()
  local lines = get_lines(bufnr)
  local section_index = find_section(lines, heading)

  if not section_index then
    local block = {
      cfg.day_separator,
      heading,
      "",
      cfg.sections.day.todo,
      "",
      cfg.sections.day.in_progress,
      "",
      cfg.sections.day.archive,
      "",
    }

    local insert_index = 1

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
    notify("Created worklog section: " .. heading)
  else
    notify("Worklog section already exists: " .. heading)
  end

  local day_end = find_day_end(lines, section_index)
  local todo_index = find_section(lines, cfg.sections.day.todo, section_index, day_end)
  local target_line = todo_index and (todo_index + 1) or (section_index + 1)

  if target_line > #lines then
    target_line = #lines
  end

  vim.api.nvim_win_set_cursor(0, { target_line, 0 })
end

local SYSTEM_METADATA = {
  start = true,
  started = true,
  ["end"] = true,
  done = true,
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
  refresh_visuals()
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

function M.metadata_add_or_update()
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

function M.metadata_edit_value()
  local bufnr, line_number, _, line, metadata = current_line_metadata()

  if not metadata then
    notify("Put cursor on @tag(value) first")
    return
  end

  local value = metadata_prompt("Value for @" .. metadata.tag .. ": ", metadata.value)
  if value == "" then
    return
  end

  local replacement = "@" .. metadata.tag .. "(" .. value .. ")"
  set_current_line(bufnr, line_number, replace_metadata_segment(line, metadata, replacement))
end

function M.metadata_remove()
  local bufnr, line_number, _, line, metadata = current_line_metadata()

  if not metadata then
    local tag = metadata_prompt("Remove tag: ")

    if tag == "" then
      return
    end

    metadata = find_first_metadata_for_tag(line, tag)
    if not metadata then
      notify("No @" .. tag .. " metadata on current line")
      return
    end
  end

  local new_line = replace_metadata_segment(line, metadata, "")
  new_line = new_line:gsub("%s+", " "):gsub("%s+$", "")
  set_current_line(bufnr, line_number, new_line)
end

function M.metadata_toggle()
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

function M.metadata_remove_user()
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

    if SYSTEM_METADATA[tag] then
      table.insert(output, line:sub(start_col, end_col))
    end

    last_end = end_col + 1
    search_from = end_col + 1
  end

  local new_line = table.concat(output):gsub("%s+", " "):gsub("%s+$", "")
  set_current_line(bufnr, line_number, new_line)
end

function M.metadata_jump(next_direction)
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

  notify("No metadata tag found")
end

local function create_commands()
  vim.api.nvim_create_user_command("TodoNormalizeSections", markdown_only("TodoNormalizeSections", M.normalize), {
    desc = "Normalize TODO sections in current worklog day or globally",
  })

  vim.api.nvim_create_user_command("TodoMoveInProgress", markdown_only("TodoMoveInProgress", M.mark_in_progress), {
    desc = "Mark TODO in progress and move to current IN PROGRESS section",
  })

  vim.api.nvim_create_user_command("TodoCreate", markdown_only("TodoCreate", M.create_todo), {
    desc = "Create TODO in current TODO section",
  })

  vim.api.nvim_create_user_command("TodoCreateInProgress", markdown_only("TodoCreateInProgress", M.create_in_progress), {
    desc = "Create TODO in current IN PROGRESS section",
  })

  vim.api.nvim_create_user_command("TodoToday", markdown_only("TodoToday", M.today), {
    desc = "Create or jump to today's worklog section",
  })
end

local function set_key(mode, lhs, rhs, desc)
  if lhs == nil or lhs == false or lhs == "" then
    return
  end

  map(mode, lhs, rhs, {
    desc = desc,
    silent = true,
  })
end

local function create_mappings()
  local keys = cfg.keys or {}

  set_key("n", keys.today, markdown_only("Create/jump to today worklog", M.today), "Worklog: today")
  set_key("n", keys.today_alt, markdown_only("Create/jump to today worklog", M.today), "Worklog: today")
  set_key("n", keys.create, markdown_only("Create TODO", M.create_todo), "Worklog: create TODO")

  set_key({ "n", "v" }, keys.cycle_next, markdown_only("Cycle TODO state", M.cycle_next), "Worklog: cycle TODO state")
  set_key({ "n", "v" }, keys.cycle_next_alt, markdown_only("Cycle TODO state", M.cycle_next), "Worklog: cycle TODO state")
  set_key({ "n", "v" }, keys.cycle_previous, markdown_only("Cycle TODO state backwards", M.cycle_previous), "Worklog: cycle TODO state backwards")
  set_key({ "n", "v" }, keys.cycle_previous_alt, markdown_only("Cycle TODO state backwards", M.cycle_previous), "Worklog: cycle TODO state backwards")
  set_key({ "n", "v" }, keys.done, markdown_only("Mark TODO done", M.mark_done), "Worklog: mark done")
  set_key({ "n", "v" }, keys.unchecked, markdown_only("Mark TODO unchecked", M.mark_unchecked), "Worklog: mark unchecked")
  set_key({ "n", "v" }, keys.remove_marker, markdown_only("Remove TODO marker", M.remove_marker), "Worklog: remove TODO marker")
  set_key({ "n", "v" }, keys.in_progress, markdown_only("Mark TODO in progress", M.mark_in_progress), "Worklog: mark in progress")

  set_key("n", keys.normalize, markdown_only("Normalize TODO sections", M.normalize), "Worklog: normalize TODO sections")
  set_key("n", keys.metadata_add_or_update, markdown_only("Metadata: add/update tag", M.metadata_add_or_update), "Worklog metadata: add/update tag")
  set_key("n", keys.metadata_toggle, markdown_only("Metadata: toggle tag", M.metadata_toggle), "Worklog metadata: toggle tag")
  set_key("n", keys.metadata_remove, markdown_only("Metadata: remove tag", M.metadata_remove), "Worklog metadata: remove tag")
  set_key("n", keys.metadata_remove_user, markdown_only("Metadata: remove user tags", M.metadata_remove_user), "Worklog metadata: remove user tags")
  set_key("n", keys.metadata_edit_value, markdown_only("Metadata: edit value", M.metadata_edit_value), "Worklog metadata: edit value")
  set_key("n", keys.metadata_next, markdown_only("Metadata: next tag", function()
    M.metadata_jump(true)
  end), "Worklog metadata: next tag")
  set_key("n", keys.metadata_previous, markdown_only("Metadata: previous tag", function()
    M.metadata_jump(false)
  end), "Worklog metadata: previous tag")
end

local function setup_checkmate()
  if not (cfg.checkmate and cfg.checkmate.enabled) then
    return
  end

  local ok, checkmate = pcall(require, "checkmate")
  if not ok then
    return
  end

  safe_call("checkmate.nvim", function()
    checkmate.setup({
      enabled = true,
      notify = cfg.notify ~= false,
      files = { "*.md" },
      default_list_marker = "-",
      smart_toggle = {
        enabled = false,
      },
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
          marker = MARKERS.unicode_unchecked,
          order = 1,
        },
        in_progress = {
          marker = MARKERS.unicode_in_progress,
          markdown = "/",
          type = "incomplete",
          order = 2,
        },
        checked = {
          marker = MARKERS.unicode_done,
          order = 3,
        },
      },
      keys = {},
      list_continuation = {
        enabled = true,
        split_line = true,
      },
    })
  end)
end

function M.setup(opts)
  cfg = deep_extend(vim.deepcopy(defaults), opts or {})

  if cfg.commands then
    create_commands()
  end

  if cfg.mappings then
    create_mappings()
  end

  setup_checkmate()
end

function M.config()
  return vim.deepcopy(cfg)
end

M._private = {
  get_todo_state = get_todo_state,
  set_todo_state = set_todo_state,
  remove_todo_marker = remove_todo_marker,
  strip_worklog_time_metadata = strip_worklog_time_metadata,
  build_worklog_todo_suffix = build_worklog_todo_suffix,
}

return M
