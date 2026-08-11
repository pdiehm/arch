package greetd greetd-tuigreet
copy res/greetd.toml /etc/greetd/config.toml
systemd -e greetd.service

package fontconfig noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji ttf-cascadia-code-nerd
symlink -u res/fontconfig.xml .config/fontconfig/fonts.conf

package pipewire pipewire-alsa pipewire-pulse wireplumber wiremix alsa-utils
persist -u .local/state/wireplumber

package hyprland hyprpaper hyprlock hypridle hyprshot hyprpicker xdg-desktop-portal-hyprland adwaita-icon-theme
symlink -u res/hypr .config/hypr
symlink -u res/keyboard.xkb .local/share/keyboard.xkb
symlink -u res/wallpaper.jpg .local/share/wallpaper.jpg

package kitty rofi waybar mako brightnessctl playerctl libnotify
symlink -u res/kitty.conf .config/kitty/kitty.conf
symlink -u res/rofi.rasi .config/rofi/config.rasi
symlink -u res/waybar .config/waybar
symlink -u res/mako.conf .config/mako/config
