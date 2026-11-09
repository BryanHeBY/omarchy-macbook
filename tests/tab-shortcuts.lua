-- Use Lua stubs to test app groups, key forwarding, window fallback and asynchronous key release.
-- Run with lua tests/tab-shortcuts.lua.
local directory = arg[0]:match("^(.*)/") or "."
local callbacks, events, timers = {}, {}, {}
local active_window = nil

hl = {
  get_active_window = function() return active_window end,
  dispatch = function(event) table.insert(events, event) end,
  timer = function(callback, options)
    assert(options.timeout == 50 and options.type == "oneshot")
    table.insert(timers, callback)
  end,
  dsp = {
    send_key_state = function(spec) return { kind = "key", spec = spec } end,
    window = { close = function(target) return { kind = "close", target = target } end },
  },
}
o = { rebind = function(key, description, callback) callbacks[key] = callback end }
dofile(directory .. "/../hyprland/tab-shortcuts.lua")

local function check(class, tags, mods, close_key, new_key)
  for _, action in ipairs({ { "SUPER + W", close_key }, { "SUPER + T", new_key } }) do
    events, timers = {}, {}
    active_window = { class = class, tags = tags, address = "0x123" }
    callbacks[action[1]]()
    if action[2] then
      assert(#events == 1 and events[1].kind == "key", class)
      local down = events[1].spec
      assert(down.mods == mods and down.key == action[2], class)
      assert(down.window == "address:0x123" and down.state == "down", class)
      assert(#timers == 1, class)
      active_window = { class = "another-window", address = "0x456" }
      timers[1]()
      local up = events[2].spec
      assert(up.mods == mods and up.key == action[2] and up.state == "up", class)
      assert(up.window == "address:0x123", "Key release must target the original window")
    elseif action[1] == "SUPER + W" then
      assert(#events == 1 and events[1].kind == "close", class)
      assert(events[1].target == "address:0x123" and #timers == 0, class)
    else
      assert(#events == 0 and #timers == 0, class)
    end
  end
end

for _, class in ipairs({
  "com.microsoft.VSCode", "com.visualstudio.code", "Code",
  "code-insiders", "Code - Insiders", "code-oss", "Code - OSS",
  "VSCodium", "com.vscodium.codium", "Cursor", "Windsurf",
  "org.kde.kate", "org.gnome.gedit", "sublime_text",
}) do
  check(class, {}, "CTRL", "W", "N")
end
for _, class in ipairs({ "org.gnome.Nautilus", "Thunar", "org.kde.dolphin", "nemo", "obsidian" }) do
  check(class, {}, "CTRL", "W", "T")
end
for _, class in ipairs({ "org.kde.konsole", "gnome-terminal-server", "xfce4-terminal", "org.wezfurlong.wezterm", "com.mitchellh.ghostty" }) do
  check(class, {}, "CTRL SHIFT", "W", "T")
end
check("kitty", {}, "CTRL SHIFT", "Q", "T")
check("browser", { "chromium-based-browser*" }, "CTRL", "W", "T")
check("browser", { "firefox-based-browser" }, "CTRL", "W", "T")
-- Exact app rules take precedence over browser tags so Electron editors create documents.
check("com.microsoft.VSCode", { "chromium-based-browser*" }, "CTRL", "W", "N")
check("foot", { "terminal*" }, nil, nil, nil)
check("Alacritty", { "terminal" }, nil, nil, nil)
check("chatgpt", {}, nil, nil, nil)
check("", nil, nil, nil, nil)
active_window, events, timers = nil, {}, {}
callbacks["SUPER + W"]()
callbacks["SUPER + T"]()
assert(#events == 0 and #timers == 0)
print("PASS tab shortcuts, application aliases, browser tags, fallback and key release")
