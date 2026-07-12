conf -e /etc/pacman.conf Color
copy res/mirrorlist /etc/pacman.d/mirrorlist
write -a /etc/pacman.conf "[aur]" "Server = https://pdiehm.github.io/aur"

run pacman-key --add "$(use res/aur.pub)"
run pacman-key --lsign-key "FE3A61A8A1C70F006D5718250AAB0BC4ED614894"
run pacman --files --refresh

upgrade pacman --noconfirm --sync --refresh --sysupgrade
upgrade pacman --files --refresh
timer pacman-gc monthly /usr/bin/pacman --noconfirm --sync --clean
