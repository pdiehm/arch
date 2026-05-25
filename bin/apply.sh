#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

if (($# != 1)); then fatal "Usage: apply.sh <host>"; fi
if ((UID)); then fatal "This script must be run as root"; fi
if ! resolve_host "$1"; then fatal "Host '$1' not found"; fi

trap cleanup EXIT
TMP="$(mktemp -d)"
chmod 700 "$TMP"

STAGE=0

cleanup() {
  if mountpoint --quiet "$TMP/root"; then unmount "$TMP/root"; fi
  if mountpoint --quiet "$TMP/boot"; then unmount "$TMP/boot"; fi
  rm -rf --one-file-system "$TMP"
}

# error <message>
error() {
  echo -e "[\e[31mERROR\e[m] $*" >&2

  for ((src = 0; src < ${#FUNCNAME[@]} - 1; src++)); do
    if [[ ${BASH_SOURCE[src + 1]} == "$0" ]]; then continue; fi
    echo "  at ${BASH_SOURCE[src + 1]}:${BASH_LINENO[src]} (${FUNCNAME[src]})" >&2
  done

  kill "$$"
}

# resolve <path>
resolve() {
  local path="$1"

  if [[ $path == - ]]; then
    echo "/dev/stdin"
  elif [[ $path == ./* ]]; then
    path="$(dirname "$MODULE")/${path#./}"
    echo "${path#./}"
  else
    echo "$path"
  fi
}

# import <path>
import() {
  local path="$1"
  path="$(resolve "$path")"
  if [[ $path == /* ]]; then error "Cannot import absolute path '$path'"; fi

  for path in "$path" "$path.sh" "$path/main.sh"; do
    if [[ ! -f $path ]]; then continue; fi
    if [[ -f $TMP/stages/$STAGE/build.sh ]]; then mkdir -p "$TMP/stages/$((++STAGE))/res"; fi

    # shellcheck disable=SC1090
    MODULE="$path" source "$path"

    if [[ -f $TMP/stages/$STAGE/build.sh ]]; then mkdir -p "$TMP/stages/$((++STAGE))/res"; fi
    return
  done

  error "Cannot find module '$1'"
}

# run <command> ...
run() {
  echo "${*@Q}" >> "$TMP/stages/$STAGE/build.sh"
  sha <<< "$*" >> "$TMP/stages/$STAGE/hash"
}

# use [path]
use() {
  local path="${1:--}"
  path="$(resolve "$path")"
  if [[ $path == /* && $path != /dev/stdin ]]; then error "Cannot use absolute path '$path'"; fi

  local resources=("$TMP/stages/$STAGE/res"/*)
  local target="$TMP/stages/$STAGE/res/${#resources[@]}"

  if [[ -d $path ]]; then
    cp -r "$path" "$target"
  elif [[ -e $path ]]; then
    cp "$path" "$target"
    if [[ $path == /dev/stdin ]]; then chmod 444 "$target"; fi
  else
    error "Resource '$path' not found"
  fi

  if [[ -f $target ]]; then
    sha < "$target" >> "$TMP/stages/$STAGE/hash"
  elif [[ -d $target ]]; then
    find "$target" -type f -exec cat "{}" + | sha >> "$TMP/stages/$STAGE/hash"
  else
    error "Cannot hash resource '$path'"
  fi

  echo "${target/#"$TMP/stages/$STAGE"//stage}"
}

# secret [-fq] <name>
secret() {
  local OPTIND opt
  local file=0 query=0

  while getopts "fq" opt; do
    case "$opt" in
      f) file=1 ;;
      q) query=1 ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  if ((file + query > 1)); then error "Options '-f' and '-q' are mutually exclusive"; fi

  local name="$1" key value
  while read -r key value; do
    if [[ $key != "$name" ]]; then continue; fi
    if [[ $key != keys/* ]]; then value="$(decode_secret "$value")"; fi

    if ((file)); then
      echo "$value" | use
    elif ((!query)); then
      echo "$value"
    fi

    return
  done < "$TMP/secrets"

  if ((query)); then return 1; fi
  error "Secret '$name' not found"
}

if [[ ! -f secrets/$HOST_NAME ]]; then
  fatal "No secrets for host '$HOST_NAME'"
fi

if [[ -f /var/local/syscfg/key ]]; then
  if ! load_secrets "secrets/$HOST_NAME" "$TMP/secrets" "$(< /var/local/syscfg/key)"; then
    warn "Stale host key"
  fi
fi

if [[ ! -f $TMP/secrets ]]; then
  if [[ -f /var/local/syscfg/master ]]; then
    if ! load_secrets secrets/master "$TMP/master" "$(< /var/local/syscfg/master)"; then
      warn "Stale master password"
    fi
  fi

  if [[ ! -f $TMP/master ]]; then
    read -rsp "Enter master password: " read
    echo

    if ! load_secrets secrets/master "$TMP/master" "$(encode_secret "$read")"; then
      fatal "Incorrect master password"
    fi
  fi

  while read -r key value; do
    if [[ $key == keys/$HOST_NAME ]]; then
      if ! load_secrets "secrets/$HOST_NAME" "$TMP/secrets" "$value"; then
        fatal "Incorrect host key"
      else
        break
      fi
    fi
  done < "$TMP/master"

  if [[ ! -f $TMP/secrets ]]; then fatal "No key for host '$HOST_NAME'"; fi
  rm "$TMP/master"
fi

mkdir -p "$TMP/stages/$STAGE/res"
import main

if [[ -n ${DRY:+x} ]]; then
  (cd "$TMP" && bash)
  exit
fi

mount --mkdir --label root "$TMP/root"
HASH="$(sha base)"

btrfs property set "$TMP/root" compression zstd
if [[ ! -d $TMP/root/images ]]; then mkdir "$TMP/root/images"; fi
if [[ ! -d $TMP/root/perm ]]; then btrfs subvolume create "$TMP/root/perm"; fi
if [[ ! -d $TMP/root/pkgs ]]; then btrfs subvolume create "$TMP/root/pkgs"; fi
if [[ -d $TMP/root/build ]]; then btrfs subvolume delete --recursive "$TMP/root/build"; fi

if [[ -n ${CLEAN:+x} || ! -d $TMP/root/images/$HASH ]]; then
  btrfs subvolume create "$TMP/root/build"
  mount --bind "$TMP/root/build" "$TMP/root/build"
  mount --mkdir --bind "$TMP/root/pkgs" "$TMP/root/build/var/cache/pacman/pkg"

  pacstrap -G "$TMP/root/build"
  arch-chroot "$TMP/root/build" bash -c "pacman-key --init && pacman-key --populate"
  arch-chroot "$TMP/root/build" mkdir -m 1777 /perm
  unmount "$TMP/root/build"

  if [[ -d $TMP/root/images/$HASH ]]; then btrfs subvolume delete --recursive "$TMP/root/images/$HASH"; fi
  mv "$TMP/root/build" "$TMP/root/images/$HASH"
fi

for ((stage = 0; stage < STAGE; stage++)); do
  hash="$(sha "$HASH+$(sha < "$TMP/stages/$stage/hash")")"
  touch "$TMP/root/images/$HASH"

  if [[ -n ${CLEAN:+x} || ! -d $TMP/root/images/$hash ]]; then
    btrfs subvolume snapshot "$TMP/root/images/$HASH" "$TMP/root/build"
    mount --bind "$TMP/root/build" "$TMP/root/build"
    mount --bind "$TMP/root/pkgs" "$TMP/root/build/var/cache/pacman/pkg"
    mount --mkdir --bind "$TMP/stages/$stage" "$TMP/root/build/stage"

    arch-chroot "$TMP/root/build" env -i SHELL=/bin/bash SYSTEMD_IN_CHROOT=1 bash -eu /stage/build.sh
    unmount "$TMP/root/build"
    rmdir "$TMP/root/build/stage"

    if [[ -d $TMP/root/images/$hash ]]; then btrfs subvolume delete --recursive "$TMP/root/images/$hash"; fi
    mv "$TMP/root/build" "$TMP/root/images/$hash"
  fi

  HASH="$hash"
  touch "$TMP/root/images/$HASH"
done

rm -f "$TMP/root/latest"
ln -s "images/$HASH" "$TMP/root/latest"

mount --mkdir --label BOOT "$TMP/boot"
rm -rf "${TMP:?}/boot"/*
cp -r "$TMP/root/latest/boot/." "$TMP/boot"

for path in "$TMP/root/latest/perm"/*; do
  target="$TMP/root/perm/${path##*/}"
  if [[ ! -e $target ]]; then cp -a "$path" "$target"; fi
  touch "$target"
done

find "$TMP/root/images" -mindepth 1 -maxdepth 1 -mtime +0 -exec btrfs subvolume delete --recursive "{}" +
find "$TMP/root/perm" -mindepth 1 -maxdepth 1 -mtime +0 -exec rm -rf "{}" +
