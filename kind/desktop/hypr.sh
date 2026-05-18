package greetd greetd-tuigreet
copy res/greetd.toml /etc/greetd/config.toml
systemd -e greetd.service

package noto-fonts noto-fonts-extra noto-fonts-emoji ttf-cascadia-code-nerd
symlink -u res/fontconfig.xml .config/fontconfig/fonts.conf

package hyprland hyprpaper hyprlock hypridle hyprshot hyprpicker xdg-desktop-portal-hyprland
symlink -u res/hypr .config/hypr
symlink -u res/wallpaper.jpg .local/share/wallpaper.jpg

package pipewire pipewire-alsa wireplumber alsa-utils
persist -u .local/state/wireplumber
symlink -u res/bin/wp-toggle.sh .local/bin/wp-toggle

package kitty waybar rofi mako
symlink -u res/kitty.conf .config/kitty/kitty.conf
symlink -u res/waybar .config/waybar
symlink -u res/rofi.rasi .config/rofi/config.rasi
symlink -u res/mako.conf .config/mako/config
