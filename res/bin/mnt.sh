#!/usr/bin/env bash

set -euo pipefail
set +m

trap 'rmdir "$TMP"' EXIT
TMP="$(mktemp -d)"

DEV="${1:-}"
UNMOUNT="sleep 1; while fuser --mount ${TMP@Q} &> /dev/null; do sleep 1; done; umount ${TMP@Q}"

if [[ -z $DEV ]]; then
  echo "Usage: mnt <dev>"
  exit 1
elif [[ $DEV == tmpfs ]]; then
  sudo mount -t tmpfs tmpfs "$TMP"
  sudo bash -c "$UNMOUNT" &
elif [[ $DEV == android ]]; then
  aft-mtp-mount "$TMP"
  bash -c "$UNMOUNT" &
elif [[ $DEV == ssh://* ]]; then
  sshfs "$(sed -E "s|^ssh://([^:]+)(:(.*))?$|\1:\3|" <<< "$DEV")" "$TMP"
  bash -c "$UNMOUNT" &
else
  for DEV in "$DEV" "/dev/$DEV" "/dev/disk/by-label/$DEV" "/dev/disk/by-partlabel/$DEV" ""; do
    if [[ -b $DEV || -f $DEV ]]; then
      sudo mount "$DEV" "$TMP"
      sudo bash -c "$UNMOUNT" &
      break
    fi
  done

  if [[ -z $DEV ]]; then
    echo "Cannot mount '$1'"
    exit 1
  fi
fi

env -C "$TMP" "$SHELL" || true
echo "Unmounting..."
wait
