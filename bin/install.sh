#!/usr/bin/env bash

set -euo pipefail

if ((UID != 0)); then
  echo "This script must be run as root"
  exit 1
fi

if ! ping -c 1 1.1.1.1 &> /dev/null; then
  echo "No network connection"
  exit 1
fi

if [[ ! -f bin/lib.sh ]]; then
  TMP="$(mktemp -d)"
  pacman --noconfirm --sync --refresh --needed git
  git clone --recurse-submodules --depth 1 https://github.com/pdiehm/arch.git "$TMP"

  cd "$TMP"
  exec bin/install.sh < /dev/tty
fi

source bin/lib.sh

HOST_NAME=""
until resolve_host "$HOST_NAME"; do
  read -rp "Enter host name: " HOST_NAME
done

DISK=""
until [[ -b $DISK ]]; do
  lsblk --output NAME,MODEL,SIZE,PARTLABEL,LABEL
  echo

  read -rp "Enter disk to install to: " DISK
  if [[ ! -b $DISK ]]; then DISK="/dev/$DISK"; fi
done

CRYPT=""
while true; do
  read -rsp "Enter disk encryption password: " CRYPT
  echo
  if [[ -z $CRYPT ]]; then break; fi

  read -rsp "Confirm password: " read
  echo
  if [[ $CRYPT == "$read" ]]; then break; fi
done

if [[ $HOST_BOOT == EFI ]]; then
  CFG=("label: gpt" "size=1GiB, type=uefi, name=BOOT, bootable" "size=8GiB, type=swap, name=swap" "type=linux, name=root")
else
  CFG=("label: dos" "size=1GiB, type=0c, name=BOOT, bootable" "size=8GiB, type=swap, name=swap" "type=linux, name=root")
fi

wipefs --all "$DISK"
printf "%s\n" "${CFG[@]}" | sfdisk "$DISK"

if [[ $HOST_BOOT == EFI ]]; then
  PART_BOOT="/dev/disk/by-partlabel/BOOT"
  PART_SWAP="/dev/disk/by-partlabel/swap"
  PART_ROOT="/dev/disk/by-partlabel/root"
else
  while [[ -z ${PARTS[1]+x} ]]; do
    mapfile -t PARTS < <(lsblk --noheadings --paths --output KNAME "$DISK")
  done

  PART_BOOT="${PARTS[1]}"
  PART_SWAP="${PARTS[2]}"
  PART_ROOT="${PARTS[3]}"
fi

until [[ -b $PART_BOOT ]]; do sleep 1; done
until [[ -b $PART_SWAP ]]; do sleep 1; done
until [[ -b $PART_ROOT ]]; do sleep 1; done

if [[ -n $CRYPT ]]; then
  cryptsetup luksFormat "$PART_ROOT" <<< "$CRYPT"
  cryptsetup open "$PART_ROOT" root <<< "$CRYPT"
  PART_ROOT="/dev/mapper/root"
fi

mkfs.fat -F 32 -n BOOT "$PART_BOOT"
mkswap --label swap "$PART_SWAP"
mkfs.btrfs --force --label root "$PART_ROOT"

until [[ -b /dev/disk/by-label/BOOT ]]; do sleep 1; done
until [[ -b /dev/disk/by-label/swap ]]; do sleep 1; done
until [[ -b /dev/disk/by-label/root ]]; do sleep 1; done

exec bin/apply.sh "$HOST_NAME"
