-- Optional MacBook-style capture shortcuts, alongside Omarchy's capture keys.
-- Number-row keycodes replace the matching workspace-move bindings explicitly.
o.rebind("SUPER + SHIFT + code:12", "Save full-screen screenshot", "omarchy capture screenshot fullscreen save")
o.rebind("SUPER + SHIFT + code:13", "Save region or window screenshot", "omarchy capture screenshot smart save")
o.rebind("SUPER + SHIFT + code:14", "Screenshot and recording menu", { menu = "capture" })
o.rebind("SUPER + CTRL + SHIFT + code:12", "Copy full-screen screenshot", "omarchy capture screenshot fullscreen copy")
o.rebind("SUPER + CTRL + SHIFT + code:13", "Copy region or window screenshot", "omarchy capture screenshot smart copy")
