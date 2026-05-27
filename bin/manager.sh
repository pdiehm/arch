#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

help() {
  echo "Usage: manager.sh <command>"
  echo
  echo "Commands:"
  echo "  help             Print this help message"
  echo "  edit             Open editor in configuration repository"
  echo "  fix              Edit latest image"
  echo "  rebuild [-hcd]   Rebuild system configuration"
  echo "  secrets [-hr]    Manage secrets"
  echo "  sync             Sync configuration repository"
  echo "  upgrade          Upgrade system"
}

edit() {
  exec "$EDITOR" .
}

fix() {
  if ((UID)); then
    exec sudo "$0" fix
  fi

  trap 'unmount "$TMP/root"; unmount "$TMP/boot"; rm -rf --one-file-system "$TMP"' EXIT
  TMP="$(mktemp -d)"
  chmod 700 "$TMP"

  mount --mkdir --label root "$TMP/root"
  if [[ -d $TMP/root/build ]]; then btrfs subvolume delete --recursive "$TMP/root/build"; fi

  btrfs subvolume snapshot "$TMP/root/latest" "$TMP/root/build"
  mount --bind "$TMP/root/build" "$TMP/root/build"
  mount --bind "$TMP/root/pkgs" "$TMP/root/build/var/cache/pacman/pkg"
  mount --bind -o ro "$TMP/root/perm" "$TMP/root/build/perm"

  if ! arch-chroot "$TMP/root/build"; then
    fatal "Shell exited with non-zero status, aborting..."
  fi

  touch "$TMP/root/build"
  unmount "$TMP/root/build"

  hash="$(readlink "$TMP/root/latest")"
  hash="$(sha "${hash##*/}++")"
  if [[ -d $TMP/root/images/$hash ]]; then btrfs subvolume delete --recursive "$TMP/root/images/$hash"; fi

  mv "$TMP/root/build" "$TMP/root/images/$hash"
  rm -f "$TMP/root/latest"
  ln -s "images/$hash" "$TMP/root/latest"

  mount --mkdir --label BOOT "$TMP/boot"
  rm -rf "${TMP:?}/boot"/*
  cp -r "$TMP/root/latest/boot/." "$TMP/boot"
}

rebuild() {
  if ((UID)); then
    exec sudo "$0" rebuild "$@"
  fi

  local OPTIND opt
  local help=0 clean=0 dry=0

  while getopts "hcd" opt; do
    case "$opt" in
      h) help=1 ;;
      c) clean=1 ;;
      d) dry=1 ;;
      *) fatal "Illegal option" ;;
    esac
  done

  if ((help)); then
    echo "Usage: manager.sh rebuild [-hcd]"
    echo
    echo "Options:"
    echo "  -h   Print this help message"
    echo "  -c   Clean rebuild"
    echo "  -d   Dry mode"
    return
  fi

  if ((clean + dry > 1)); then
    fatal "Options '-c' and '-d' are mutually exclusive"
  fi

  if ((clean)); then export CLEAN=1; fi
  if ((dry)); then export DRY=1; fi
  exec bin/apply.sh "$HOSTNAME"
}

secrets() {
  if ((UID)); then
    exec sudo "$0" secrets "$@"
  fi

  local OPTIND opt
  local help=0 rotate=0

  while getopts "hr" opt; do
    case "$opt" in
      h) help=1 ;;
      r) rotate=1 ;;
      *) fatal "Illegal option" ;;
    esac
  done

  if ((help)); then
    echo "Usage: manager.sh secrets [-hr]"
    echo
    echo "Options:"
    echo "  -h   Print this help message"
    echo "  -r   Rotate keys"
    return
  fi

  trap 'rm -rf "$TMP"' EXIT
  TMP="$(mktemp -d)"

  chmod 700 "$TMP"
  mkdir "$TMP/store"

  if [[ -f secrets/master && -f /var/local/syscfg/master ]]; then
    if ! load_secrets secrets/master "$TMP/store" "$(< /var/local/syscfg/master)"; then
      warn "Stale master password"
    fi
  fi

  if [[ ! -f $TMP/store/ACL ]]; then
    read -rsp "Enter master password: " read
    echo

    if [[ -f secrets/master ]]; then
      if ! load_secrets secrets/master "$TMP/store" "$(sha "$read")"; then
        fatal "Incorrect master password"
      fi
    else
      touch "$TMP/store/ACL"
      mkdir "$TMP/store/keys"
      sha "$read" > "$TMP/store/keys/master"
    fi
  fi

  if ! env -C "$TMP/store" bash; then
    fatal "Shell exited with non-zero status, aborting..."
  fi

  mkdir "$TMP/keys"
  mv "$TMP/store/keys/master" "$TMP/keys"

  if ((rotate)); then
    read -rsp "Enter new master password: " read
    echo

    sha "$read" > "$TMP/keys/master"
    rm -rf "$TMP/store/keys"
  fi

  while read -r host _; do
    if [[ $host == master ]]; then
      fatal "Illegal host name: $name"
    elif [[ -f $TMP/store/keys/$host ]]; then
      mv "$TMP/store/keys/$host" "$TMP/keys"
    else
      head -c 64 /dev/urandom | sha > "$TMP/keys/$host"
    fi
  done < "$TMP/store/ACL"

  rm -rf "$TMP/store/keys"
  mv "$TMP/keys" "$TMP/store"

  mkdir "$TMP/secrets"
  store_secrets "$TMP/secrets/master" "$TMP/store" "$(< "$TMP/store/keys/master")" .

  while read -r host spec; do
    read -ra args <<< "$spec"
    if ! store_secrets "$TMP/secrets/$host" "$TMP/store" "$(< "$TMP/store/keys/$host")" "keys/$host" "${args[@]}"; then
      warn "Illegal ACL for host '$host', store might be incomplete."
    fi
  done < "$TMP/store/ACL"

  rm -rf secrets
  mv "$TMP/secrets" .
  chown -R "$(stat -c "%u:%g" .)" secrets
}

sync() {
  git pull --recurse-submodules=on-demand
  ahead="$(git rev-list --count "@{upstream}..")"
  if ((ahead == 0)); then return; fi

  read -rp "Push local commits? [y/N] " read
  if [[ $read == y ]]; then git push; fi
}

upgrade() {
  if ((UID)); then
    exec sudo "$0" upgrade
  fi

  trap 'unmount "$TMP/root"; unmount "$TMP/boot"; rm -rf --one-file-system "$TMP"' EXIT
  TMP="$(mktemp -d)"
  chmod 700 "$TMP"

  mount --mkdir --label root "$TMP/root"
  if [[ -d $TMP/root/build ]]; then btrfs subvolume delete --recursive "$TMP/root/build"; fi

  btrfs subvolume snapshot "$TMP/root/latest" "$TMP/root/build"
  mount --bind "$TMP/root/build" "$TMP/root/build"
  mount --bind "$TMP/root/pkgs" "$TMP/root/build/var/cache/pacman/pkg"
  mount --bind -o ro "$TMP/root/perm" "$TMP/root/build/perm"

  if ! arch-chroot "$TMP/root/build" bash -eu /var/local/syscfg/upgrade.sh; then
    fatal "Upgrade failed"
  fi

  touch "$TMP/root/build"
  unmount "$TMP/root/build"

  hash="$(readlink "$TMP/root/latest")"
  hash="$(sha "${hash##*/}++")"
  if [[ -d $TMP/root/images/$hash ]]; then btrfs subvolume delete --recursive "$TMP/root/images/$hash"; fi

  mv "$TMP/root/build" "$TMP/root/images/$hash"
  rm -f "$TMP/root/latest"
  ln -s "images/$hash" "$TMP/root/latest"

  mount --mkdir --label BOOT "$TMP/boot"
  rm -rf "${TMP:?}/boot"/*
  cp -r "$TMP/root/latest/boot/." "$TMP/boot"
}

if (($# == 0)); then
  help
  exit 1
fi

case "$1" in
  help) help ;;
  edit) edit ;;
  fix) fix ;;
  rebuild) rebuild "${@:2}" ;;
  secrets) secrets "${@:2}" ;;
  sync) sync ;;
  upgrade) upgrade ;;
  *) fatal "Illegal command: $1" ;;
esac
