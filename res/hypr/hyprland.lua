require("hyprland.main")
require("hyprland.binds")
require("hyprland.animations")

if io.open("/home/pascal/.config/hypr/hyprland/dropin.lua") ~= nil then
  require("hyprland.dropin")
end
