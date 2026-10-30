conf -e /etc/pacman.conf Color VerbosePkgLists
copy res/mirrorlist /etc/pacman.d/mirrorlist
write -a /etc/fstab "LABEL=root /var/cache/pacman/pkg btrfs subvol=pkgs 0 2"

run pacman-key --init
run pacman-key --populate
run pacman-key --add "$(use res/aur.pub)"
run pacman-key --lsign-key "2E0A8522A1B73901C93EF024DF9F6915A409F6E8"
write -a /etc/pacman.conf "" "[aur]" "Server = https://pdiehm.github.io/aur"

package arch-install-scripts dosfstools btrfs-progs cryptsetup sudo gcc git
timer pacman-gc monthly /usr/bin/pacman --noconfirm --sync --clean
upgrade pacman --noconfirm --sync --refresh --sysupgrade
upgrade pacman --files --refresh

# HACK: https://gitlab.archlinux.org/pacman/pacman/-/work_items/297
write /etc/systemd/system/pacman-gc.service.d/remove-dirs.conf << EOF
[Service]
ExecStartPost=/usr/bin/find /var/cache/pacman/pkg -type d -empty -delete
EOF
