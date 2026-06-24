#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

overlay() {
  trap 'unmount "$MNT/root"; unmount "$MNT/boot"; rm -rf --one-file-system "$MNT"' EXIT
  TMP="$(mktemp -d)"
  chmod 700 "$TMP"

  mount --mkdir --label root "$TMP/root"
  if [[ -d $TMP/root/build ]]; then btrfs subvolume delete --recursive "$TMP/root/build"; fi

  btrfs subvolume snapshot "$TMP/root/latest" "$TMP/root/build"
  mount --bind "$TMP/root/build" "$TMP/root/build"
  mount --bind "$TMP/root/pkgs" "$TMP/root/build/var/cache/pacman/pkg"
  mount --bind -o ro "$TMP/root/perm" "$TMP/root/build/perm"

  if ! arch-chroot "$TMP/root/build" "$@"; then
    fatal "Process '$*' exited with non-zero status, aborting..."
  fi

  touch "$TMP/root/build"
  unmount "$TMP/root/build"

  local hash
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
  overlay bash
}

rebuild() {
  local OPTIND opt
  local help=0 break=0 clean=0 dry=0

  while getopts "hbcn" opt; do
    case "$opt" in
      h) help=1 ;;
      b) break=1 ;;
      c) clean=1 ;;
      n) dry=1 ;;
      *) fatal "Illegal option" ;;
    esac
  done

  if ((help)); then
    echo "Usage: manager.sh rebuild [-hbcn] [host]"
    echo
    echo "Options:"
    echo "  -h   Print this help message"
    echo "  -b   Break after evaluation"
    echo "  -c   Clean rebuild"
    echo "  -n   Skip activation"
    return
  fi

  if ((UID)); then
    exec sudo "$0" rebuild "$@"
  fi

  shift $((OPTIND - 1))
  local host="${1:-$HOSTNAME}"

  if ((break)); then export SM_BREAK=1; fi
  if ((clean)); then export SM_CLEAN=1; fi
  if ((dry)); then export SM_DRY=1; fi
  exec bin/apply.sh "$host"
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
    read -rsp "Enter master password: "
    echo

    if [[ -f secrets/master ]]; then
      if ! load_secrets secrets/master "$TMP/store" "$(sha "$REPLY")"; then
        fatal "Incorrect master password"
      fi
    else
      touch "$TMP/store/ACL"
      mkdir "$TMP/store/keys"
      sha "$REPLY" > "$TMP/store/keys/master"
    fi
  fi

  if ! env -C "$TMP/store" bash; then
    fatal "Shell exited with non-zero status, aborting..."
  fi

  mkdir "$TMP/keys"
  mv "$TMP/store/keys/master" "$TMP/keys"

  if ((rotate)); then
    read -rsp "Enter new master password: "
    echo

    sha "$REPLY" > "$TMP/keys/master"
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

  while read -r host args; do
    read -ra spec <<< "$args"

    if ! store_secrets "$TMP/secrets/$host" "$TMP/store" "$(< "$TMP/store/keys/$host")" "keys/$host" "${spec[@]}"; then
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

  read -rp "Push local commits? [y/N] "
  if [[ $REPLY == y ]]; then git push; fi
}

upgrade() {
  if ((UID)); then exec sudo "$0" upgrade; fi
  overlay bash -eu /var/local/syscfg/upgrade.sh
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
