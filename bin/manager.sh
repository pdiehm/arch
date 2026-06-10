#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

build-prepare() {
  trap 'unmount "$MNT/root"; unmount "$MNT/boot"; rm -rf --one-file-system "$MNT"' EXIT
  MNT="$(mktemp -d)"
  chmod 700 "$MNT"

  mount --mkdir --label root "$MNT/root"
  if [[ -d $MNT/root/build ]]; then btrfs subvolume delete --recursive "$MNT/root/build"; fi

  btrfs subvolume snapshot "$MNT/root/latest" "$MNT/root/build"
  mount --bind "$MNT/root/build" "$MNT/root/build"
  mount --bind "$MNT/root/pkgs" "$MNT/root/build/var/cache/pacman/pkg"
  mount --bind -o ro "$MNT/root/perm" "$MNT/root/build/perm"
}

build-commit() {
  touch "$MNT/root/build"
  unmount "$MNT/root/build"

  local hash
  hash="$(readlink "$MNT/root/latest")"
  hash="$(sha "${hash##*/}++")"
  if [[ -d $MNT/root/images/$hash ]]; then btrfs subvolume delete --recursive "$MNT/root/images/$hash"; fi

  mv "$MNT/root/build" "$MNT/root/images/$hash"
  rm -f "$MNT/root/latest"
  ln -s "images/$hash" "$MNT/root/latest"

  mount --mkdir --label BOOT "$MNT/boot"
  rm -rf "${MNT:?}/boot"/*
  cp -r "$MNT/root/latest/boot/." "$MNT/boot"
}

help() {
  echo "Usage: manager.sh <command>"
  echo
  echo "Commands:"
  echo "  help             Print this help message"
  echo "  edit             Open editor in configuration repository"
  echo "  fix              Edit latest image"
  echo "  rebuild [-hbc]   Rebuild system configuration"
  echo "  secrets [-hr]    Manage secrets"
  echo "  sync             Sync configuration repository"
  echo "  upgrade          Upgrade system"
}

edit() {
  exec "$EDITOR" .
}

fix() {
  if ((UID)); then exec sudo "$0" fix; fi
  build-prepare

  if arch-chroot "$MNT/root/build"; then
    build-commit
  else
    fatal "Shell exited with non-zero status, aborting..."
  fi
}

rebuild() {
  local OPTIND opt
  local help=0 break=0 clean=0

  while getopts "hbc" opt; do
    case "$opt" in
      h) help=1 ;;
      b) break=1 ;;
      c) clean=1 ;;
      *) fatal "Illegal option" ;;
    esac
  done

  if ((help)); then
    echo "Usage: manager.sh rebuild [-hbc]"
    echo
    echo "Options:"
    echo "  -h   Print this help message"
    echo "  -b   Break after evaluation"
    echo "  -c   Clean rebuild"
    return
  fi

  if ((UID)); then exec sudo "$0" rebuild "$@"; fi
  if ((break)); then export BREAK=1; fi
  if ((clean)); then export CLEAN=1; fi
  exec bin/apply.sh "$HOSTNAME"
}

secrets() {
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

  if ((UID)); then exec sudo "$0" secrets "$@"; fi
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
    if [[ $host == master || $host =~ [^a-zA-Z0-9-] ]]; then
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
  git pull
  ahead="$(git rev-list --count "@{upstream}..")"
  if ((ahead == 0)); then return; fi

  read -rp "Push local commits? [y/N] " read
  if [[ $read == y ]]; then git push; fi
}

upgrade() {
  if ((UID)); then exec sudo "$0" upgrade; fi
  build-prepare

  if arch-chroot "$MNT/root/build" bash -eu /var/local/syscfg/upgrade.sh; then
    build-commit
  else
    fatal "Upgrade failed"
  fi
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
