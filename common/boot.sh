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
run mkinitcpio --preset linux

option cpu
if [[ $PHASE == build ]]; then
  if [[ -z $OPT_CPU ]]; then error "CPU option is required"; fi
  if [[ $OPT_CPU != amd && $OPT_CPU != intel ]]; then error "Unsupported CPU '$OPT_CPU'"; fi
  package "$OPT_CPU-ucode"
fi

if [[ $HOST_BOOT == EFI ]]; then
  cmd="mkdir -p /boot/EFI/BOOT && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT"
else
  cmd="cp /usr/share/limine/limine-bios.sys /boot && limine bios-install \"\$(lsblk --noheadings --paths --output PKNAME /dev/disk/by-label/BOOT)\""
fi

package limine
script <<< "$cmd"
upgrade <<< "$cmd"

write /boot/limine.conf << EOF
timeout: 0

/Arch
  protocol: linux
  path: boot():/vmlinuz-linux
  cmdline: rw root=LABEL=root rootflags=subvol=root cryptdevice=/dev/disk/by-partlabel/root:root
  module_path: boot():/$OPT_CPU-ucode.img
  module_path: boot():/initramfs-linux.img
EOF
