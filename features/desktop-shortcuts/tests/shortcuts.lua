-- Verify native editing chords, contextual deletion and focus-safe key release.
local directory = arg[0]:match("^(.*)/") or "."
local callbacks, events, timers = {}, {}, {}
local active = nil
hl = {
  get_active_window = function() return active end,
  dispatch = function(event) table.insert(events, event) end,
  timer = function(callback, options)
    assert(options.timeout == 50 and options.type == "oneshot")
    table.insert(timers, callback)
  end,
  dsp = { send_key_state = function(spec) return spec end },
}
o = { rebind = function(key, description, action) callbacks[key] = action end }
dofile(directory .. "/../hyprland.lua")

local function invoke(key, class, tags)
  events, timers = {}, {}
  active = { address = "0x123", class = class, tags = tags }
  callbacks[key]()
end

local function finish()
  while #timers > 0 do table.remove(timers, 1)() end
end

local function chord(index, mods, key)
  local down, up = events[index], events[index + 1]
  assert(down.mods == mods and down.key == key and down.state == "down")
  assert(up.mods == mods and up.key == key and up.state == "up")
  assert(down.window == nil and up.window == nil, "Forward to the focused surface, including shell menus")
end

for _, action in ipairs({
  { "SUPER + Z", "CTRL", "Z" }, { "SUPER + SHIFT + Z", "CTRL SHIFT", "Z" },
  { "SUPER + S", "CTRL", "S" }, { "SUPER + SHIFT + S", "CTRL SHIFT", "S" },
  { "SUPER + F", "CTRL", "F" }, { "SUPER + O", "CTRL", "O" },
  { "SUPER + P", "CTRL", "P" },
}) do
  invoke(action[1], "editor", {})
  finish()
  assert(#events == 2)
  chord(1, action[2], action[3])
  invoke(action[1], "foot", { "terminal*" })
  finish()
  assert(#events == 0)
end
for _, class in ipairs({ "org.gnome.Nautilus", "Thunar", "org.kde.dolphin", "Nemo" }) do
  invoke("SUPER + BACKSPACE", class, {})
  finish()
  assert(#events == 2)
  chord(1, "", "Delete")
end
invoke("SUPER + BACKSPACE", "foot", { "terminal*" })
finish()
chord(1, "CTRL", "U")
invoke("SUPER + BACKSPACE", "editor", nil)
finish()
assert(#events == 4)
chord(1, "SHIFT", "Home")
chord(3, "", "BackSpace")

for _, action in ipairs({ { "SUPER + L", "L" }, { "SUPER + R", "R" } }) do
  for _, window in ipairs({
    { "org.gnome.Nautilus", {} }, { "browser", { "chromium-based-browser*" } },
    { "browser", { "firefox-based-browser" } },
  }) do
    invoke(action[1], window[1], window[2])
    finish()
    chord(1, "CTRL", action[2])
  end
  invoke(action[1], "editor", {})
  finish()
  assert(#events == 0)
end

invoke("SUPER + BACKSPACE", "editor", {})
active = { address = "0x456", class = "other-window" }
finish()
assert(#events == 2, "Focus changes must stop the deletion sequence")
chord(1, "SHIFT", "Home")
events, timers, active = {}, {}, nil
for _, action in pairs(callbacks) do action() end
assert(#events == 0 and #timers == 0)
assert(not callbacks["PRINT"] and not callbacks["SUPER + SHIFT + code:12"])
print("PASS desktop editing, scoped browser actions, contextual deletion and focus changes")
