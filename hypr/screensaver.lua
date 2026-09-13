-- glyphsaver window rules (managed block).
-- Appended to ~/.config/hypr/UserConfigs/user_window_rules.lua by `setup`.
-- Requires the KoolDots apply_window_rule helper already present in that file.
apply_window_rule({
  name = "glyphsaver",
  match = { class = "glyphsaver" },
  float = true,
  fullscreen = true,
  border_size = 0,
  no_shadow = true,
  no_anim = true,
})
