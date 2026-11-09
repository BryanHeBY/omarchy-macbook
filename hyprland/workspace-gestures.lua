-- 三指、四指横滑识别后立即切换一次工作区。左滑到下一工作区，右滑到上一工作区。
-- 使用 r+1/r-1 包含空工作区，避免跟手拖动回弹。

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

-- Two-finger horizontal scrolling cycles focus in multi-window tiled workspaces.
require("hypr.customizations.two-finger-focus")

for _, fingers in ipairs({ 3, 4 }) do
  hl.gesture({ fingers = fingers, direction = "left", action = workspace_step("r+1") })
  hl.gesture({ fingers = fingers, direction = "right", action = workspace_step("r-1") })
end
