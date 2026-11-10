-- Natural scrolling belongs to the touchpad and retains the mouse policy.
local applied
hl = { config = function(settings) applied = settings end }
dofile("features/touchpad-scrolling/hyprland.lua")
assert(applied.input.touchpad.natural_scroll == true)
assert(applied.input.natural_scroll == nil)
print("PASS touchpad-only natural scrolling configuration")
