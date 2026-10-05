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
  curl -fsSL https://github.com/pdiehm/arch/archive/refs/heads/main.tar.gz | tar xz
  exec env -C arch-main bin/install.sh < /dev/tty
fi

source bin/lib.sh

HOST_NAME=""
until load_host "$HOST_NAME"; do
  read -rp "Enter host name: " HOST_NAME
done

DISK=""
until [[ -b $DISK ]]; do
  lsblk --output NAME,TYPE,SIZE,PARTLABEL,LABEL
  echo

  read -rp "Select disk: " DISK
  if [[ ! -b $DISK ]]; then DISK="/dev/$DISK"; fi
done

CRYPT="" REPLY="-"
while [[ $CRYPT != "$REPLY" ]]; do
  read -rsp "Enter disk encryption password: " CRYPT
  echo

  read -rsp "Confirm password: "
  echo
done

if [[ $HOST_BOOT == efi ]]; then
  CFG=("label: gpt" "size=1GiB, type=uefi, name=BOOT, bootable" "type=linux, name=root")
elif [[ $HOST_BOOT == bios ]]; then
  CFG=("label: dos" "size=1GiB, type=0c, name=BOOT, bootable" "type=linux, name=root")
else
  fatal "Illegal boot method: $HOST_BOOT"
fi

wipefs --all "$DISK"
printf "%s\n" "${CFG[@]}" | sfdisk "$DISK"
until [[ -b ${PARTS[1]:-} ]]; do mapfile -t PARTS < <(lsblk --noheadings --paths --output KNAME "$DISK"); done

cryptsetup luksFormat --label crypt "${PARTS[2]}" <<< "$CRYPT"
cryptsetup open "${PARTS[2]}" root <<< "$CRYPT"

mkfs.fat -F 32 -n BOOT "${PARTS[1]}"
mkfs.btrfs --force --label root /dev/mapper/root

until [[ -b /dev/disk/by-label/BOOT ]]; do sleep 1; done
until [[ -b /dev/disk/by-label/crypt ]]; do sleep 1; done
until [[ -b /dev/disk/by-label/root ]]; do sleep 1; done

export SM_REBOOT=1
export SM_CRYPT="$CRYPT"
exec bin/build.sh "$HOST_NAME"
