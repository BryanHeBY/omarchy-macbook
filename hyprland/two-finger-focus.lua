-- Optional native input filter. Build it with scripts/build-two-finger-focus.sh.
-- Loading on each reload keeps the plugin requested by the Hyprland config.
local data_home = os.getenv("XDG_DATA_HOME")
if not data_home or data_home == "" then
  data_home = os.getenv("HOME") .. "/.local/share"
end
local library = data_home .. "/omarchy-configs/plugins/two-finger-focus.so"
local file = io.open(library, "rb")
if file then
  file:close()
  hl.plugin.load(library)
end
