write -a /etc/fstab << EOF
LABEL=root /                     btrfs subvol=root 0 1
LABEL=swap none                  swap  defaults    0 0
LABEL=BOOT /boot                 vfat  defaults    0 2
LABEL=root /perm                 btrfs subvol=perm 0 2
LABEL=root /var/cache/pacman/pkg btrfs subvol=pkgs 0 2
tmpfs      /home/pascal/Temp     tmpfs defaults    0 0
EOF

copy res/initcpio/root/hook.sh /etc/initcpio/hooks/root
copy res/initcpio/root/install.sh /etc/initcpio/install/root
conf /etc/mkinitcpio.conf "HOOKS=(base udev autodetect microcode keyboard block encrypt filesystems root fsck)"
run mkinitcpio --preset linux

package limine "$HOST_CPU-ucode"
env UCODE "$HOST_CPU-ucode.img"
copy -e res/limine.conf /boot/limine.conf

if [[ $HOST_BOOT == EFI ]]; then
  script <<< "mkdir -p /boot/EFI/BOOT && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT"
  upgrade <<< "mkdir -p /boot/EFI/BOOT && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT"
else
  script <<< "cp /usr/share/limine/limine-bios.sys /boot && limine bios-install \"\$(lsblk --noheadings --paths --output PKNAME /dev/disk/by-label/BOOT)\""
  upgrade <<< "cp /usr/share/limine/limine-bios.sys /boot && limine bios-install \"\$(lsblk --noheadings --paths --output PKNAME /dev/disk/by-label/BOOT)\""
fi
