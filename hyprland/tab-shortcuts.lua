-- Super+W 关闭当前标签或文档，Super+T 新建标签或空白文档。
-- 按应用的 Linux 原生快捷键转发，由应用处理焦点、保存提示和最后一个标签。
local tab_keys = { mods = "CTRL", close = "W", new_tab = "T" }
local document_keys = { mods = "CTRL", close = "W", new_tab = "N" }
local terminal_keys = { mods = "CTRL SHIFT", close = "W", new_tab = "T" }
-- Kitty 的 Ctrl+Shift+Q 关闭整个标签，Ctrl+Shift+W 关闭当前分屏。
local kitty_keys = { mods = "CTRL SHIFT", close = "Q", new_tab = "T" }

-- 使用精确窗口类，避免将 Electron 应用或所有终端统一当作多标签应用。
-- 新应用可以按其默认快捷键加入对应分组，窗口类可用 hyprctl clients 查询。
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

  -- Omarchy 为浏览器提供动态标签，其名称可能带有结尾的星号。
  for _, tag in ipairs(window.tags or {}) do
    tag = tag:gsub("%*$", "")
    if tag == "chromium-based-browser" or tag == "firefox-based-browser" then
      return tab_keys
    end
  end
end

local function send_shortcut(window, shortcuts, key)
  local target = "address:" .. window.address
  -- 明确发送按下和抬起，沿用 Omarchy 的剪贴板快捷键模式。
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
