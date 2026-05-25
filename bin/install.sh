#!/usr/bin/env bash

set -euo pipefail

if ((UID)); then
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
  git clone --depth 1 https://github.com/pdiehm/arch.git "$TMP"

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
  lsblk --output NAME,VENDOR,MODEL,SIZE,PARTLABEL,LABEL
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
elif [[ $HOST_BOOT == BIOS ]]; then
  CFG=("label: dos" "size=1GiB, type=0c, name=BOOT, bootable" "size=8GiB, type=swap, name=swap" "type=linux, name=root")
else
  fatal "Illegal boot method: $HOST_BOOT"
fi

wipefs --all "$DISK"
printf "%s\n" "${CFG[@]}" | sfdisk "$DISK"

while [[ -z ${PARTS[1]:+x} ]]; do
  mapfile -t PARTS < <(lsblk --noheadings --paths --output KNAME "$DISK")
done

PART_BOOT="${PARTS[1]}"
until [[ -b $PART_BOOT ]]; do sleep 1; done

PART_SWAP="${PARTS[2]}"
until [[ -b $PART_SWAP ]]; do sleep 1; done

PART_ROOT="${PARTS[3]}"
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
