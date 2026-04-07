#!/usr/bin/ash

run_hook() {
  local tmp="$(mktemp -d)"
  mount --label root "$tmp"

  mkdir -p "$tmp/boot"
  find "$tmp/boot" -mindepth 1 -maxdepth 1 -mtime +7 -exec btrfs subvolume delete --recursive "{}" +

  if [[ -d "$tmp/root" ]]; then
    local time="$(stat -c "%y" "$tmp/root")"
    local target="$tmp/boot/${time:0:10}_${time:11:8}"
    while [[ -d $target ]]; do target="$target="; done

    mv "$tmp/root" "$target"
  fi

  btrfs subvolume snapshot "$tmp/latest" "$tmp/root"
  touch "$tmp/root"

  umount "$tmp"
  rmdir "$tmp"
}
