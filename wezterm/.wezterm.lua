-- ~/.wezterm.lua

local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

wezterm.on("gui-startup", function()
  local tab, pane, window = mux.spawn_window{}
  window:gui_window():maximize()
end)

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local index = tab.tab_index + 1
  return {
    { Text = ' ' .. index .. ' ' },
  }
end)

return {

  default_prog = { "pwsh.exe", "-NoLogo" },

  tab_bar_at_bottom = true,
  hide_tab_bar_if_only_one_tab = true,
 
  front_end = "Software",

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

    -- split jak w tmux
    { key = "v", mods = "LEADER", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "s", mods = "LEADER", action = act.SplitVertical { domain = "CurrentPaneDomain" } },

    -- nawigacja hjkl
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection "Left" },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection "Down" },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection "Up" },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection "Right" },

    -- zamknij pane
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane { confirm = false } },

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
    { key = "PageUp", mods = "LEADER", action = act.MoveTabRelative(-1) },
    { key = "PageDown", mods = "LEADER", action = act.MoveTabRelative(1) },

    -- move panes
    { key = "w", mods = "LEADER", action = act.PaneSelect { mode = "SwapWithActiveKeepFocus" } },
    { key = "W", mods = "LEADER", action = act.PaneSelect { mode = "SwapWithActive" } },
    { key = "m", mods = "LEADER", action = act.PaneSelect { mode = "MoveToNewTab" } },


  },

  -- vi-like copy mode
  key_tables = {
    copy_mode = {
      { key = "h", action = act.CopyMode "MoveLeft" },
      { key = "j", action = act.CopyMode "MoveDown" },
      { key = "k", action = act.CopyMode "MoveUp" },
      { key = "l", action = act.CopyMode "MoveRight" },
      { key = "v", action = act.CopyMode { SetSelectionMode = "Cell" } },
      { key = "y", action = act.CopyTo "ClipboardAndPrimarySelection" },
      { key = "Escape", action = act.CopyMode "Close" },
    },
  },
}
