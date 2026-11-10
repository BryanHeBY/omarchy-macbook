-- A library is inert until activation creates its marker; configure after load.
local open, getenv = io.open, os.getenv
local marker, library, ready, loads, configs = false, true, false, 0, 0
os.getenv = function(name) if name == "HOME" then return "/example" end end
io.open = function(path)
  local exists = path:match("touchpad%-inertia.enabled$") and marker or path:match("touchpad%-inertia.so$") and library
  if exists then return { close = function() end } end
end
hl = {
  plugin = { load = function() loads = loads + 1 end },
  get_config = function(name)
    assert(name == "plugin.touchpad_inertia.classes")
    if ready then return "foot,org.codeberg.dnkl.foot" end
  end,
  config = function(settings)
    assert(loads > configs, "Register native options before applying configuration")
    assert(settings.plugin.touchpad_inertia.classes == "foot,org.codeberg.dnkl.foot")
    assert(settings.plugin.touchpad_inertia.layers == "omarchy-menu")
    assert(settings.plugin["touchpad-inertia"] == nil, "Lua option namespaces use underscores")
    configs = configs + 1
  end,
}
dofile("features/touchpad-inertia/hyprland.lua")
assert(loads == 0 and configs == 0)
marker = true
dofile("features/touchpad-inertia/hyprland.lua")
assert(loads == 1 and configs == 0, "First-start deferred registration must skip unknown options")
ready = true
dofile("features/touchpad-inertia/hyprland.lua")
assert(loads == 2 and configs == 1)
library = false
dofile("features/touchpad-inertia/hyprland.lua")
assert(loads == 2 and configs == 1)
io.open, os.getenv = open, getenv
print("PASS touchpad inertia opt-in, missing-library guard and native configuration order")
