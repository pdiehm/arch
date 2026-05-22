local function dpms()
  hl.timer(function()
    hl.dispatch(hl.dsp.dpms({ action = "off" }))
  end, { timeout = 1000, type = "oneshot" })
end

for id = 1, 9 do
  hl.bind("SUPER + " .. id, hl.dsp.focus({ workspace = id }))
  hl.bind("SUPER + SHIFT + " .. id, hl.dsp.window.move({ workspace = id }))
  hl.bind("CTRL + SUPER + " .. id, hl.dsp.window.move({ workspace = id, follow = false }))
end

for key, dir in pairs({ H = "left", J = "down", K = "up", L = "right" }) do
  hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = dir }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

hl.bind("SUPER + 0", hl.dsp.workspace.toggle_special("special"))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + 0", hl.dsp.window.move({ workspace = "special:special", follow = false }))

hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
hl.bind("CTRL + SUPER + SHIFT + Q", hl.dsp.window.kill(), { bypass = true })

hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"))

hl.bind("SUPER + Escape", dpms, { locked = true })
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("CTRL + SUPER + SHIFT + Escape", hl.dsp.exit(), { bypass = true })

hl.bind("Print", hl.dsp.exec_cmd("hyprshot --mode active --mode output --output-folder /home/pascal/Temp"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd("hyprshot --mode active --mode window --output-folder /home/pascal/Temp"))
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("hyprshot --mode region --output-folder /home/pascal/Temp"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("hyprpicker --autocopy"))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%-"), { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("SHIFT + XF86AudioMute", hl.dsp.exec_cmd("~/.local/bin/wp-toggle"), { locked = true })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "swipe", action = "resize", mods = "SUPER" })
