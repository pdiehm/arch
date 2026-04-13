package greetd-tuigreet
run systemctl enable greetd.service

write /etc/greetd/config.toml << EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd zsh"

[initial_session]
command = "systemd-cat --identifier Hyprland start-hyprland"
user = "pascal"
EOF

package noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk ttf-firacode-nerd
symlink -u res/fontconfig.xml .config/fontconfig/fonts.conf

package hyprland kitty rofi
symlink -u res/hypr .config/hypr
