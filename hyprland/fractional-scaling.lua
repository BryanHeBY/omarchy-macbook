-- Allow exact fractional display scales, including 1.8 on non-divisible modes.
-- Logical monitor dimensions are rounded, so fractional pixel alignment can vary.
-- Load before monitor rules, together with the display-controls Shell plugin.
hl.config({ debug = { disable_scale_checks = true } })
