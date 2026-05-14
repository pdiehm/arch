package greetd greetd-tuigreet
copy res/greetd.toml /etc/greetd/config.toml
systemd greetd.service

package noto-fonts noto-fonts-extra noto-fonts-emoji ttf-firacode-nerd
symlink -u res/fontconfig.xml .config/fontconfig/fonts.conf

package hyprland hyprpaper hyprlock hypridle hyprshot hyprpicker xdg-desktop-portal-hyprland
symlink -u res/hypr .config/hypr
symlink -u res/wallpaper.jpg .local/share/wallpaper.jpg

package pipewire pipewire-alsa wireplumber alsa-utils wiremix
persist -u .local/state/wireplumber
symlink -u res/bin/wp-toggle.sh .local/bin/wp-toggle

package alacritty waybar rofi mako
symlink -u res/alacritty.toml .config/alacritty.toml
symlink -u res/waybar .config/waybar
symlink -u res/rofi.rasi .config/rofi/config.rasi
symlink -u res/mako.conf .config/mako/config
