write -a /etc/fstab << EOF
LABEL=root /                     btrfs subvol=root 0 1
LABEL=swap none                  swap  defaults    0 0
LABEL=BOOT /boot                 vfat  defaults    0 2
LABEL=root /perm                 btrfs subvol=perm 0 2
LABEL=root /var/cache/pacman/pkg btrfs subvol=pkgs 0 2
EOF

copy res/initcpio/root/hook.sh /etc/initcpio/hooks/root
copy res/initcpio/root/install.sh /etc/initcpio/install/root
conf /etc/mkinitcpio.conf "HOOKS=(base udev autodetect microcode keyboard block encrypt filesystems root fsck)"
run mkinitcpio --allpresets

package limine "$HOST_CPU-ucode"
env CPU "$HOST_CPU"
env KERNEL "$HOST_KERNEL"
copy -e res/limine.conf /boot/limine.conf

if [[ $HOST_BOOT == EFI ]]; then
  script <<< "mkdir -p /boot/EFI/BOOT && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT"
  upgrade <<< "mkdir -p /boot/EFI/BOOT && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT"
elif [[ $HOST_BOOT == BIOS ]]; then
  script <<< 'cp /usr/share/limine/limine-bios.sys /boot && limine bios-install "$(lsblk --noheadings --paths --output PKNAME /dev/disk/by-label/BOOT)"'
  upgrade <<< 'cp /usr/share/limine/limine-bios.sys /boot && limine bios-install "$(lsblk --noheadings --paths --output PKNAME /dev/disk/by-label/BOOT)"'
else
  error "Illegal boot method: $HOST_BOOT"
fi
