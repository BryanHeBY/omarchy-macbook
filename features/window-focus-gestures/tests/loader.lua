-- A compiled library alone must never enable the optional gesture.
local original_open, original_getenv = io.open, os.getenv
local marker = false
local library = true
local loads = 0
os.getenv = function(name)
  if name == "HOME" then return "/example" end
  return nil
end
io.open = function(path)
  local exists = path:match("two%-finger%-focus.enabled$") and marker
    or path:match("two%-finger%-focus.so$") and library
  if exists then return { close = function() end } end
end
hl = { plugin = { load = function() loads = loads + 1 end } }

dofile("features/window-focus-gestures/hyprland.lua")
assert(loads == 0, "A compiled library must remain disabled without explicit opt-in")
marker = true
dofile("features/window-focus-gestures/hyprland.lua")
assert(loads == 1, "An enabled marker and library must load the plugin")
library = false
dofile("features/window-focus-gestures/hyprland.lua")
assert(loads == 1, "A missing library must be skipped")

io.open, os.getenv = original_open, original_getenv
print("PASS two-finger explicit opt-in and missing-library handling")
