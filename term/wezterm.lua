local wezterm = require 'wezterm'
local localrc = require 'localrc'

-- I like having tabs from multiple domains in the same window. Include the
-- domain name in the tab title.
wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local title = tab.tab_title
  if not title or #title == 0 then
    title = pane.title
  end
  if pane.domain_name and pane.domain_name ~= 'local' then
    title = '[' .. pane.domain_name .. '] ' .. title
  end
  return title
end)

-- Send an stty command to set the terminal size. Useful for serial consoles.
wezterm.on('send-stty-size', function(window, pane)
  local dimensions = pane:get_dimensions()
  window:perform_action(
    wezterm.action.Multiple {
      wezterm.action.SendString ('stty cols ' .. dimensions['cols'] .. ' rows ' .. dimensions['viewport_rows']),
      wezterm.action.SendKey { key = 'Enter' },
    },
    pane
  )
end)

config = {
  font_size = 10.0,
  bold_brightens_ansi_colors = 'No',
  colors = {
    foreground = '#000000',
    background = '#ffffff',

    cursor_bg = '#000000',
    cursor_fg = '#ffffff',
    cursor_border = '#000000',

    selection_fg = '#ffffff',
    selection_bg = '#3584e4',

    ansi = {
      '#000000',
      '#aa0000',
      '#00aa00',
      '#aa5500',
      '#0000aa',
      '#aa00aa',
      '#00aaaa',
      '#aaaaaa',
    },
    brights = {
      '#555555',
      '#ff5555',
      '#55ff55',
      '#ffff55',
      '#5555ff',
      '#ff55ff',
      '#55ffff',
      '#ffffff',
    },

    copy_mode_active_highlight_bg = { AnsiColor = 'Aqua' },
    copy_mode_active_highlight_fg = { AnsiColor = 'Black' },
    copy_mode_inactive_highlight_bg = { AnsiColor = 'Aqua' },
    copy_mode_inactive_highlight_fg = { AnsiColor = 'Black' },

    quick_select_label_bg = { AnsiColor = 'Black' },
    quick_select_label_fg = { AnsiColor = 'Aqua' },
    quick_select_match_bg = { AnsiColor = 'Aqua' },
    quick_select_match_fg = { AnsiColor = 'Black' },
  },
  window_decorations = 'RESIZE',
  keys = {
    -- Move between panes with Vim-like keys.
    {
      key = 'H',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Left',
    },
    {
      key = 'J',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Down',
    },
    {
      key = 'K',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Up',
    },
    {
      key = 'L',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Right',
    },
    -- Shortcut to send an stty command to set the terminal size.
    {
      key = 'S',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.EmitEvent 'send-stty-size',
    },
  },
  mouse_bindings = {
    -- Only copy selected text to primary selection, not clipboard.
    -- CompleteSelection or CompleteSelectionOrOpenLinkAtMouseCursor are chosen
    -- to be consistent with the default mouse bindings as of wezterm
    -- 20230703_104831_71dcb07b, although I don't know if there's any reasoning
    -- behind those choices.
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor('PrimarySelection'),
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'SHIFT',
      action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor('PrimarySelection'),
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'ALT',
      action = wezterm.action.CompleteSelection('PrimarySelection'),
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'SHIFT|ALT',
      action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor('PrimarySelection'),
    },
    {
      event = { Up = { streak = 2, button = 'Left' } },
      mods = 'NONE',
      action = wezterm.action.CompleteSelection('PrimarySelection'),
    },
    {
      event = { Up = { streak = 3, button = 'Left' } },
      mods = 'NONE',
      action = wezterm.action.CompleteSelection('PrimarySelection'),
    },
  },
}

localrc.apply_to_config(config)
return config
