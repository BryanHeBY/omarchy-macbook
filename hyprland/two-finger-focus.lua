-- Optional native input filter, explicitly enabled by configure-two-finger-focus.py.
-- Loading on each reload keeps the plugin requested by the Hyprland config.
local config_home = os.getenv("XDG_CONFIG_HOME")
if not config_home or config_home == "" then
  config_home = os.getenv("HOME") .. "/.config"
end
local enabled = io.open(config_home .. "/omarchy-macbook/two-finger-focus.enabled", "rb")
if not enabled then return end
enabled:close()

local data_home = os.getenv("XDG_DATA_HOME")
if not data_home or data_home == "" then
  data_home = os.getenv("HOME") .. "/.local/share"
end
local library = data_home .. "/omarchy-macbook/plugins/two-finger-focus.so"
local file = io.open(library, "rb")
if file then
  file:close()
  hl.plugin.load(library)
end
