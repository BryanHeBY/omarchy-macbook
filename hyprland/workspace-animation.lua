-- Use an ease-out curve for workspace slide transitions with speed set to 3.2.
-- workspace-gestures.lua triggers each switch; the compositor animates the transition.

-- Animate recognized workspace switches with an ease-out slide.
hl.curve("macWorkspaceEase", {
  type = "bezier",
  points = { { 0.22, 1 }, { 0.36, 1 } },
})
hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 3.2,
  bezier = "macWorkspaceEase",
  style = "slide",
})
