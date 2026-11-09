-- Switch once per recognized three- or four-finger swipe: left goes next, right goes previous.
-- Use r+1/r-1 to include empty workspaces and avoid interactive drag rebound.

-- Switch workspaces with discrete three- and four-finger swipes.
-- See https://wiki.hypr.land/configuring/core/binds/gestures/
-- Switch once as soon as a horizontal swipe is recognized.
-- Keep natural direction: swipe left goes to the next workspace.
local function workspace_step(target)
  return {
    start = function()
      hl.dispatch(hl.dsp.focus({ workspace = target }))
    end,
  }
end

for _, fingers in ipairs({ 3, 4 }) do
  hl.gesture({ fingers = fingers, direction = "left", action = workspace_step("r+1") })
  hl.gesture({ fingers = fingers, direction = "right", action = workspace_step("r-1") })
end
