package "$HOST_KERNEL" linux-firmware
copy res/initcpio/root/hook.sh /etc/initcpio/hooks/root
copy res/initcpio/root/install.sh /etc/initcpio/install/root
conf /etc/mkinitcpio.conf "HOOKS=(base udev autodetect microcode modconf keyboard block encrypt filesystems root fsck)"
run mkinitcpio --allpresets

package limine "$HOST_CPU-ucode"
var CPU "$HOST_CPU"
var KERNEL "$HOST_KERNEL"
copy -v res/limine.conf /boot/limine.conf

if [[ $HOST_BOOT == efi ]]; then
  script <<< "mkdir -p /boot/EFI/BOOT && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT"
  upgrade <<< "mkdir -p /boot/EFI/BOOT && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT"
elif [[ $HOST_BOOT == bios ]]; then
  script <<< 'cp /usr/share/limine/limine-bios.sys /boot && limine bios-install "$(lsblk --noheadings --paths --output PKNAME /dev/disk/by-label/BOOT)"'
  upgrade <<< 'cp /usr/share/limine/limine-bios.sys /boot && limine bios-install "$(lsblk --noheadings --paths --output PKNAME /dev/disk/by-label/BOOT)"'
else
  error "Illegal boot method: $HOST_BOOT"
fi
