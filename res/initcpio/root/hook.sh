#!/usr/bin/ash

run_hook() {
  local tmp="$(mktemp -d)" boot="$(resolve_device LABEL=BOOT)" root="$(resolve_device LABEL=crypt)"
  if [[ ! -b $root ]]; then return 1; fi
  modprobe -aq dm-crypt

  if [[ -b $boot ]] && mount "$boot" "$tmp"; then
    if [[ -f $tmp/crypt ]]; then
      cryptsetup open --key-file "$tmp/crypt" "$root" root
      shred -u "$tmp/crypt"
    fi

    umount "$tmp"
  fi

  until [[ -b /dev/mapper/root ]]; do
    cryptsetup open "$root" root
  done

  if mount /dev/mapper/root "$tmp"; then
    mkdir -p "$tmp/boot"
    find "$tmp/boot" -mindepth 1 -maxdepth 1 -mtime +7 -exec btrfs subvolume delete --recursive "{}" +

    if [[ -d $tmp/root ]]; then
      local time="$(stat -c "%y" "$tmp/root")"
      local target="$tmp/boot/${time:0:10}_${time:11:8}"

      while [[ -d $target ]]; do target="${target}_"; done
      mv "$tmp/root" "$target"
    fi

    btrfs subvolume snapshot "$tmp/base" "$tmp/root"
    touch "$tmp/root"
    umount "$tmp"
  fi
}
