#!/usr/bin/env bash

set -euo pipefail
trap 'rmdir "$TMP"' EXIT
TMP="$(mktemp -d)"

DEV="${1:-}"
UNMOUNT="read && echo 'Unmounting...' && umount ${TMP@Q}"

if [[ -z $DEV ]]; then
  echo "Usage: mnt <dev>"
  exit 1
elif [[ $DEV == tmpfs ]]; then
  sudo mount -t tmpfs tmpfs "$TMP"
  exec 5> >(sudo bash -c "$UNMOUNT")
elif [[ $DEV == android ]]; then
  aft-mtp-mount "$TMP"
  exec 5> >(bash -c "$UNMOUNT")
elif [[ $DEV == ssh://* ]]; then
  sshfs "$(sed -E "s|^ssh://([^:]+)(:(.*))?$|\1:\3|" <<< "$DEV")" "$TMP"
  exec 5> >(bash -c "$UNMOUNT")
else
  for dev in "$DEV" "/dev/$DEV" "/dev/disk/by-label/$DEV" "/dev/disk/by-partlabel/$DEV" ""; do
    if [[ -b $dev || -f $dev ]]; then
      sudo mount "$dev" "$TMP"
      exec 5> >(sudo bash -c "$UNMOUNT")
      break
    fi
  done

  if [[ -z $dev ]]; then
    echo "Cannot mount '$1'"
    exit 1
  fi
fi

env -C "$TMP" "$SHELL" || true
echo >&5
wait
