package greetd greetd-tuigreet
copy res/greetd.toml /etc/greetd/config.toml
run systemctl enable greetd.service

package noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk ttf-firacode-nerd
symlink -u res/fontconfig.xml .config/fontconfig/fonts.conf

package hyprland hyprpaper hyprlock hypridle hyprshot hyprpicker xdg-desktop-portal-hyprland
symlink -u res/hypr .config/hypr
symlink -u res/wallpaper.jpg .local/share/wallpaper.jpg

package kitty waybar rofi mako
symlink -u res/waybar .config/waybar
