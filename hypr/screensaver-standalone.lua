-- glyphsaver window rules (managed by glyphsaver-setup).
-- Loaded via a `dofile` line in hyprland.lua. Self-contained: works with any
-- Lua-mode Hyprland, no KoolDots/helper required. Failures are swallowed so
-- a mismatch can never break the rest of your config.
if hl and hl.window_rule then
  pcall(hl.window_rule, {
    name = "glyphsaver",
    match = { class = "glyphsaver" },
    float = true,
    fullscreen = true,
    noborder = true,
    noshadow = true,
    no_anim = true,
  })
end
