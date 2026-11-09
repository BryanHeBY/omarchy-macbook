-- Super+W closes the current tab or document; Super+T creates a tab or blank document.
-- Forward native Linux shortcuts so each app handles focus, save prompts and its last tab.
local tab_keys = { mods = "CTRL", close = "W", new_tab = "T" }
local document_keys = { mods = "CTRL", close = "W", new_tab = "N" }
local terminal_keys = { mods = "CTRL SHIFT", close = "W", new_tab = "T" }
-- Kitty uses Ctrl+Shift+Q to close a tab and Ctrl+Shift+W to close the current split.
local kitty_keys = { mods = "CTRL SHIFT", close = "Q", new_tab = "T" }

-- Match exact window classes to distinguish Electron editors and terminal tab support.
-- Add apps to the group matching their default shortcuts; inspect classes with hyprctl clients.
local shortcuts_by_class = {
  ["org.gnome.nautilus"] = tab_keys,
  ["nautilus"] = tab_keys,
  ["org.kde.dolphin"] = tab_keys,
  ["dolphin"] = tab_keys,
  ["org.xfce.thunar"] = tab_keys,
  ["thunar"] = tab_keys,
  ["nemo"] = tab_keys,
  ["obsidian"] = tab_keys,

  ["com.microsoft.vscode"] = document_keys,
  ["com.visualstudio.code"] = document_keys,
  ["code"] = document_keys,
  ["code-insiders"] = document_keys,
  ["code - insiders"] = document_keys,
  ["com.microsoft.vscode.insiders"] = document_keys,
  ["code-oss"] = document_keys,
  ["code - oss"] = document_keys,
  ["vscodium"] = document_keys,
  ["codium"] = document_keys,
  ["com.vscodium.codium"] = document_keys,
  ["cursor"] = document_keys,
  ["com.todesktop.230313mzl4w4u92"] = document_keys,
  ["windsurf"] = document_keys,
  ["org.kde.kate"] = document_keys,
  ["kate"] = document_keys,
  ["org.kde.kwrite"] = document_keys,
  ["kwrite"] = document_keys,
  ["org.gnome.gedit"] = document_keys,
  ["gedit"] = document_keys,
  ["sublime_text"] = document_keys,
  ["sublime-text"] = document_keys,

  ["org.kde.konsole"] = terminal_keys,
  ["konsole"] = terminal_keys,
  ["org.gnome.terminal"] = terminal_keys,
  ["gnome-terminal"] = terminal_keys,
  ["gnome-terminal-server"] = terminal_keys,
  ["org.xfce.terminal"] = terminal_keys,
  ["xfce4-terminal"] = terminal_keys,
  ["org.wezfurlong.wezterm"] = terminal_keys,
  ["wezterm"] = terminal_keys,
  ["com.mitchellh.ghostty"] = terminal_keys,
  ["ghostty"] = terminal_keys,
  ["kitty"] = kitty_keys,
}

local function shortcuts_for(window)
  local shortcuts = shortcuts_by_class[(window.class or ""):lower()]
  if shortcuts then return shortcuts end

  -- Omarchy supplies dynamic browser tags whose names may end with an asterisk.
  for _, tag in ipairs(window.tags or {}) do
    tag = tag:gsub("%*$", "")
    if tag == "chromium-based-browser" or tag == "firefox-based-browser" then
      return tab_keys
    end
  end
end

local function send_shortcut(window, shortcuts, key)
  local target = "address:" .. window.address
  -- Send explicit key-down and key-up events, following Omarchy clipboard shortcut handling.
  hl.dispatch(hl.dsp.send_key_state({ mods = shortcuts.mods, key = key, state = "down", window = target }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = shortcuts.mods, key = key, state = "up", window = target }))
  end, { timeout = 50, type = "oneshot" })
end

o.rebind("SUPER + W", "Close tab or window", function()
  local window = hl.get_active_window()
  if not window then return end

  local shortcuts = shortcuts_for(window)
  if shortcuts then
    send_shortcut(window, shortcuts, shortcuts.close)
  else
    hl.dispatch(hl.dsp.window.close("address:" .. window.address))
  end
end)

o.rebind("SUPER + T", "New tab or document", function()
  local window = hl.get_active_window()
  if not window then return end

  local shortcuts = shortcuts_for(window)
  if shortcuts then
    send_shortcut(window, shortcuts, shortcuts.new_tab)
  end
end)
