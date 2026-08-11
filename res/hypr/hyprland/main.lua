hl.env("GTK_THEME", "Adwaita:dark")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

hl.on("hyprland.start", function()
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("waybar")
  hl.exec_cmd("XDG_MENU_PREFIX=arch- kbuildsycoca6")
end)

hl.config({
  binds = {
    hide_special_on_workspace_change = true,
  },

  cursor = {
    hide_on_key_press = true,
  },

  decoration = {
    rounding = 10,
    dim_special = 0.5,
  },

  dwindle = {
    force_split = 2,
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },

  general = {
    border_size = 2,
    no_focus_fallback = true,
    resize_on_border = true,

    col = {
      active_border = {
        colors = { "#60efff", "#0061ff" },
        angle = 45,
      },
    },
  },

  input = {
    kb_file = "~/.local/share/keyboard.xkb",
    numlock_by_default = true,
    repeat_delay = 200,
  },

  misc = {
    disable_splash_rendering = true,
    enable_anr_dialog = false,
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})
