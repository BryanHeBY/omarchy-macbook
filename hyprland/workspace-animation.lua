-- 工作区切换采用缓出曲线，保留 slide 过渡，速度参数为 3.2。
-- 手势由 workspace-gestures.lua 直接触发，动画由合成器完成。

-- 识别手势后，以缓出曲线完成工作区滑动切换。
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
