local wezterm = require("wezterm")
local config = {}

-- Spawn a fish shell in login mode
config.default_prog = { "/usr/bin/zsh", "-l" }

-- config.enable_wayland = true
config.window_background_opacity = 0.6
config.font = wezterm.font("IosevkaTerm Nerd Font")
config.color_scheme = "Tokyo Night"
config.tab_bar_at_bottom = true
config.colors = {
  scrollbar_thumb = "white",
}
config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"
-- config.hide_tab_bar_if_only_one_tab = true

-- local dimmer = { brightness = 0.1 }
-- config.background = {
-- First layer, deepest/furthest away
-- {
--   source = {
--     File = "/var/home/blyons/Backgrounds/2834103.jpg",
--   },
--   -- Tiles vertically.
--   repeat_x = "Mirror",
--   hsb = dimmer,
--   attachment = { Parallax = 0.1 },
--   opacity = 0.4,
-- },
-- Layer 2, mid range
-- {
--   source = {
--     File = "/var/home/blyons/Backgrounds/2834100.jpg",
--   },
--   width = "100%",
--   repeat_x = "NoRepeat",
--   hsb = dimmer,
--   attachment = { Parallax = 0.2 },
--   opacity = 0.6,
-- },
-- Layer 3, closest
-- {
--   source = {
--     File = "/var/home/blyons/Backgrounds/340392.jpg",
--   },
--   attachment = { Parallax = 0.8 },
--   opacity = 0.2,
-- },
-- }

return config
