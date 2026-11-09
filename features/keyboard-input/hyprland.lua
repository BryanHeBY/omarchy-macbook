-- Session actions for the internal keyd mappings in features/keyboard-input/keyd.conf.
-- Input switching uses the same shell reader as Omarchy's Super+I shortcut.
local options = {
  ignore_mods = true,
  device = { inclusive = true, list = { "keyd-virtual-keyboard" } },
}

-- Bind XKB keycodes because standard layouts may assign media keysyms to F13-F15.
o.bind("code:191", "Switch input language with Caps Lock or Fn", "omarchy-input-method cycle", options)
o.bind("code:192", "Use direct input for uppercase typing", "fcitx5-remote --check -c", options)
o.bind("code:193", "Emojis with Fn+E", { panel = "omarchy.emojis" }, options)
o.bind("CTRL + SUPER + space", "Emojis", { panel = "omarchy.emojis" })
