-- ~/.wezterm.lua

local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

wezterm.on("gui-startup", function()
  local tab, pane, window = mux.spawn_window{}
  window:gui_window():maximize()
end)

wezterm.on('format-tab-title', function(tab)
  local zoom = tab.active_pane.is_zoomed and 'zoom ' or ''
  return ' ⟦' .. (tab.tab_index + 1) .. '⟧ ' .. zoom
end)

-- --- projekty --------------------------------------------------------------
-- Ctrl-t f: lista projektow. Wybrany otwiera sie w osobnym workspace: nvim
-- (sam wczyta sesje tego folderu) i pwsh obok. Jesli projekt jest juz otwarty,
-- tylko sie do niego przelaczasz. Ctrl-t o: wszystkie otwarte workspace'y,
-- razem z `default`, od ktorego startuje WezTerm.
--
-- Projekty = foldery, w ktorych nvim ma zapisana sesje (autocmds.lua w configu
-- nvim), jak "ostatnie foldery" w VS Code. Nowy folder pojawi sie na liscie
-- sam, po pierwszym wyjsciu z `nvim` / `nvim .` w tym folderze.
local nvim_sessions = (os.getenv('LOCALAPPDATA') or '') .. '\\nvim-data\\sessions'

local function list_projects()
  local dirs = {}
  local ok, files = pcall(wezterm.read_dir, nvim_sessions)
  if not ok then return dirs end
  for _, file in ipairs(files) do
    local f = io.open(file, 'r')
    if f then
      -- sesja zaczyna sie od `cd <folder>`: z escape'ami przed spacjami,
      -- z `/` zamiast `\` i z `~` zamiast katalogu domowego
      for line in f:lines() do
        local dir = line:match('^cd (.+)$')
        if dir then
          dir = dir:gsub('\\(.)', '%1'):gsub('^~', wezterm.home_dir):gsub('/', '\\')
          dirs[#dirs + 1] = dir
          break
        end
      end
      f:close()
    end
  end
  table.sort(dirs)
  return dirs
end

local function spawn_project(dir)
  -- nvim odpalony z pwsh, nie sam: po :q zostajesz w shellu w tym folderze
  local _, editor = mux.spawn_window {
    workspace = dir,
    cwd = dir,
    args = { 'pwsh.exe', '-NoLogo', '-NoExit', '-Command', 'nvim' },
  }
  editor:split { direction = 'Right', size = 0.5, cwd = dir }
  editor:activate()
end

local function open_project(window, pane, dir)
  local open = false
  for _, name in ipairs(mux.get_workspace_names()) do
    if name == dir then open = true end
  end
  if not open then spawn_project(dir) end
  window:perform_action(act.SwitchToWorkspace { name = dir }, pane)
end

-- Lista budowana przy kazdym otwarciu, nie przy starcie WezTerma -- inaczej
-- nowe foldery bylyby widoczne dopiero po przeladowaniu configu.
local pick_project = wezterm.action_callback(function(window, pane)
  local choices = {}
  for _, dir in ipairs(list_projects()) do
    choices[#choices + 1] = { id = dir, label = dir }
  end
  window:perform_action(act.InputSelector {
    title = 'Projekt',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(win, p, id)
      if id then open_project(win, p, id) end
    end),
  }, pane)
end)

-- nazwa biezacego workspace'u po prawej stronie paska tabow
wezterm.on('update-status', function(window)
  window:set_right_status(' ' .. window:active_workspace() .. ' ')
end)

-- --- copy mode (Ctrl-t [) ---------------------------------------------------
-- Domyslne vi-like skroty WezTerma (hjkl, w/b/e, 0/$, g/G, Ctrl-u/d, v/V/Ctrl-v,
-- y = kopiuj i wyjdz, q/Esc = wyjdz) + wyszukiwanie jak w vimie:
-- / szukaj, Enter wraca do copy mode na trafieniu, n / N nastepne / poprzednie.
-- Wlasna tabela zamiast domyslnej wylaczylaby wszystkie pozostale skroty.
local copy_mode = wezterm.gui.default_key_tables().copy_mode
table.insert(copy_mode, { key = '/', mods = 'NONE', action = act.Search 'CurrentSelectionOrEmptyString' })
table.insert(copy_mode, { key = 'n', mods = 'NONE', action = act.CopyMode 'NextMatch' })
table.insert(copy_mode, { key = 'N', mods = 'SHIFT', action = act.CopyMode 'PriorMatch' })

local search_mode = wezterm.gui.default_key_tables().search_mode
table.insert(search_mode, {
  key = 'Enter', mods = 'NONE',
  action = act.Multiple { act.CopyMode 'AcceptPattern', act.CopyMode 'ClearSelectionMode' },
})



return {
  font_size = 14.0,

  color_scheme = 'Obsidian',

  harfbuzz_features = {"calt=0", "clig=0", "liga=0"},
  default_prog = { "pwsh.exe", "-NoLogo" },

  tab_bar_at_bottom = true,

  -- dluzsza historia (domyslnie 3500 linii -- za malo na dluga sesje claude)
  scrollback_lines = 20000,

  front_end = "WebGpu",

  -- brak paddingu
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },

  -- LEADER jak prefix C-t
  leader = { key = "t", mods = "CTRL", timeout_milliseconds = 1000 },

  keys = {

    { key = "v", mods = "LEADER", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "s", mods = "LEADER", action = act.SplitVertical { domain = "CurrentPaneDomain" } },

    -- nawigacja hjkl
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection "Left" },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection "Down" },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection "Up" },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection "Right" },

    -- zamknij pane
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane { confirm = false } },
    { key = "X", mods = "LEADER", action = act.CloseCurrentTab { confirm = false } },

    -- nowe taby (jak nowe window)
    { key = "c", mods = "LEADER", action = act.SpawnTab "CurrentPaneDomain" },

    -- poprzednia / następna karta
    { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },

    -- numerowane zakładki 1-9
    { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
    { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
    { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
    { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
    { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
    { key = "6", mods = "LEADER", action = act.ActivateTab(5) },
    { key = "7", mods = "LEADER", action = act.ActivateTab(6) },
    { key = "8", mods = "LEADER", action = act.ActivateTab(7) },
    { key = "9", mods = "LEADER", action = act.ActivateTab(8) },

    -- toogle panes
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

    -- adjust pane size
    { key = "LeftArrow",  mods = "LEADER", action = act.AdjustPaneSize { "Left", 1 } },
    { key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize { "Right", 1 } },
    { key = "UpArrow",    mods = "LEADER", action = act.AdjustPaneSize { "Up", 1 } },
    { key = "DownArrow",  mods = "LEADER", action = act.AdjustPaneSize { "Down", 1 } },

    -- move tabs
    { key = "P", mods = "LEADER", action = act.MoveTabRelative(-1) },
    { key = "N", mods = "LEADER", action = act.MoveTabRelative(1) },

    -- move panes
    { key = "w", mods = "LEADER", action = act.PaneSelect { mode = "SwapWithActiveKeepFocus" } },
    { key = "W", mods = "LEADER", action = act.PaneSelect { mode = "SwapWithActive" } },
    { key = "m", mods = "LEADER", action = act.PaneSelect { mode = "MoveToNewTab" } },

    { key = "f", mods = "LEADER", action = pick_project },
    { key = "o", mods = "LEADER", action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
  
    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
    { key = "q", mods = "LEADER", action = act.PaneSelect },
  },


  key_tables = {
    copy_mode = copy_mode,
    search_mode = search_mode,
  },
}
