-- Optional screenshot keys must keep the existing Omarchy capture bindings.
local directory = arg[0]:match("^(.*)/") or "."
local bindings = { PRINT = "original screenshot", ["SUPER + CTRL + ALT + C"] = "original screenshot" }
o = { rebind = function(key, description, action) bindings[key] = action end }
dofile(directory .. "/../hyprland.lua")
assert(bindings.PRINT == "original screenshot")
assert(bindings["SUPER + CTRL + ALT + C"] == "original screenshot")
assert(bindings["SUPER + SHIFT + code:12"] == "omarchy capture screenshot fullscreen save")
assert(bindings["SUPER + SHIFT + code:13"] == "omarchy capture screenshot smart save")
assert(bindings["SUPER + SHIFT + code:14"].menu == "capture")
assert(bindings["SUPER + CTRL + SHIFT + code:12"] == "omarchy capture screenshot fullscreen copy")
assert(bindings["SUPER + CTRL + SHIFT + code:13"] == "omarchy capture screenshot smart copy")
local count = 0
for _ in pairs(bindings) do count = count + 1 end
assert(count == 7)
print("PASS optional screenshot routes and original capture binding preservation")
