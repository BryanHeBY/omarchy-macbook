-- Load this optional native plugin only after explicit local activation.
local config = os.getenv("XDG_CONFIG_HOME")
if not config or config == "" then config = os.getenv("HOME") .. "/.config" end
local marker = io.open(config .. "/omarchy-macbook/touchpad-inertia.enabled", "rb")
if not marker then return end
marker:close()

local data = os.getenv("XDG_DATA_HOME")
if not data or data == "" then data = os.getenv("HOME") .. "/.local/share" end
local library = data .. "/omarchy-macbook/plugins/touchpad-inertia.so"
local file = io.open(library, "rb")
if not file then return end
file:close()
hl.plugin.load(library)
-- A first-start plugin request may register its options after this Lua pass.
-- Hyprland reruns configuration after loading it; apply settings on that pass.
if hl.get_config("plugin.touchpad_inertia.classes") == nil then return end
-- Hyprland normalizes native plugin option names to underscores in Lua.
hl.config({ plugin = { touchpad_inertia = {
  classes = "foot,org.codeberg.dnkl.foot",
  layers = "omarchy-menu",
  decay_ms = 180,
} } })
