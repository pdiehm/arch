#!/usr/bin/env bash

SOURCE="$1"
TARGET="${2:-$SOURCE}"

if [[ ! $SOURCE ]]; then
  echo "Usage: mk <source> [target]"
  exit 1
elif [[ -e $TARGET ]]; then
  echo "$TARGET already exists"
  exit 1
elif [[ -f ~/.local/share/mk/$SOURCE ]]; then
  sed "s/@YEAR@/$(date "+%Y")/g" "$HOME/.local/share/mk/$SOURCE" > "$TARGET"
elif [[ $SOURCE == arch.iso ]]; then
  trap 'rm -rf --one-file-system "$TMP"' EXIT
  TMP="$(mktemp -d)"
  cp -r /usr/share/archiso/configs/baseline "$TMP/config"

  mkdir -p "$TMP/config/airootfs"/{etc/pacman.d,root/.ssh}
  cp /etc/pacman.d/mirrorlist "$TMP/config/airootfs/etc/pacman.d"
  printf "%s\n" arch-install-scripts dosfstools btrfs-progs cryptsetup >> "$TMP/config/packages.x86_64"
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFQ+VK4y/tYvIGxEwalz6CPuDckHooWvJT8+ZmXvUv8" > "$TMP/config/airootfs/root/.ssh/authorized_keys"
  echo "pacman-key --init && pacman-key --populate && curl -fsSL https://pdiehm.github.io/arch | sh" > "$TMP/config/airootfs/root/.bash_profile"

  mkarchiso -vr -o "$TMP/out" -w "$TMP/work" "$TMP/config"
  mv "$TMP/out"/*.iso "$TARGET"
else
  echo "Cannot make '$SOURCE'"
  exit 1
fi
