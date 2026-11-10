-- MacBook-style editing shortcuts with application-specific deletion.
local file_managers = {
  ["org.gnome.nautilus"] = true, ["nautilus"] = true,
  ["org.kde.dolphin"] = true, ["dolphin"] = true,
  ["org.xfce.thunar"] = true, ["thunar"] = true, ["nemo"] = true,
}

local function has_tag(window, name)
  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == name then return true end
  end
  return false
end

-- Follow Omarchy's clipboard down/up forwarding to the focused surface,
-- including menus. Release each chord before continuing; stop on window changes.
local function send_sequence(window, sequence, index)
  index = index or 1
  local active = hl.get_active_window()
  if not active or active.address ~= window.address then return end
  local chord = sequence[index]
  hl.dispatch(hl.dsp.send_key_state({ mods = chord[1], key = chord[2], state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = chord[1], key = chord[2], state = "up" }))
    if index < #sequence then send_sequence(window, sequence, index + 1) end
  end, { timeout = 50, type = "oneshot" })
end

-- Terminal applications interpret Ctrl-letter keys as their own control input.
-- Limit common document actions to GUI windows; terminal deletion uses Ctrl+U.
for _, binding in ipairs({
  { "SUPER + Z", "Undo", "CTRL", "Z" },
  { "SUPER + SHIFT + Z", "Redo", "CTRL SHIFT", "Z" },
  { "SUPER + S", "Save document", "CTRL", "S" },
  { "SUPER + SHIFT + S", "Save document as", "CTRL SHIFT", "S" },
  { "SUPER + F", "Find in application", "CTRL", "F" },
  { "SUPER + O", "Open in application", "CTRL", "O" },
  { "SUPER + P", "Print in application", "CTRL", "P" },
}) do
  o.rebind(binding[1], binding[2], function()
    local window = hl.get_active_window()
    if window and not has_tag(window, "terminal") then
      send_sequence(window, { { binding[3], binding[4] } })
    end
  end)
end

for _, binding in ipairs({
  { "SUPER + L", "Focus browser address or folder location", "L" },
  { "SUPER + R", "Reload browser or folder", "R" },
}) do
  o.rebind(binding[1], binding[2], function()
    local window = hl.get_active_window()
    if window and (file_managers[(window.class or ""):lower()]
        or has_tag(window, "chromium-based-browser") or has_tag(window, "firefox-based-browser")) then
      send_sequence(window, { { "CTRL", binding[3] } })
    end
  end)
end

-- Native Delete delegates trash handling and confirmation to the file manager.
-- In text controls use the application's Home selection, then delete it.
o.rebind("SUPER + BACKSPACE", "Trash selection or delete to line start", function()
  local window = hl.get_active_window()
  if not window then return end
  if file_managers[(window.class or ""):lower()] then
    send_sequence(window, { { "", "Delete" } })
  elseif has_tag(window, "terminal") then
    send_sequence(window, { { "CTRL", "U" } })
  else
    send_sequence(window, { { "SHIFT", "Home" }, { "", "BackSpace" } })
  end
end)
