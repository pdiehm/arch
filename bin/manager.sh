#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

overlay() {
  trap 'unmount "$TMP/root"; unmount "$TMP/boot"; rm -rf --one-file-system "$TMP"' EXIT
  TMP="$(mktemp -d)"
  chmod 700 "$TMP"

  mount --mkdir --label root "$TMP/root"
  if [[ -d $TMP/root/build ]]; then btrfs subvolume delete --recursive "$TMP/root/build"; fi

  btrfs subvolume snapshot "$TMP/root/base" "$TMP/root/build"
  mount --bind "$TMP/root/build" "$TMP/root/build"
  mount --bind "$TMP/root/pkgs" "$TMP/root/build/var/cache/pacman/pkg"

  if ! arch-chroot "$TMP/root/build" "$@"; then
    fatal "Process '$*' exited with non-zero status, aborting..."
  fi

  touch "$TMP/root/build"
  unmount "$TMP/root/build"

  hash="$(readlink "$TMP/root/base")"
  hash="$(sha "${hash##*/}++")"
  if [[ -d $TMP/root/imgs/$hash ]]; then btrfs subvolume delete --recursive "$TMP/root/imgs/$hash"; fi

  mv "$TMP/root/build" "$TMP/root/imgs/$hash"
  rm -f "$TMP/root/base"
  ln -s "imgs/$hash" "$TMP/root/base"

  mount --mkdir --label BOOT "$TMP/boot"
  find "$TMP/boot" -mindepth 1 -delete
  cp -r "$TMP/root/base/boot/." "$TMP/boot"
}

help() {
  echo "Usage: sm <command> [args...]"
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
    echo "Usage: sm rebuild [-hbcn] [host]"
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

  shift "$((OPTIND - 1))"
  local host="${1:-$HOSTNAME}"

  if ((break)); then export SM_BREAK=1; fi
  if ((clean)); then export SM_CLEAN=1; fi
  if ((dry)); then export SM_DRY=1; fi
  exec bin/build.sh "$host"
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
    echo "Usage: sm secrets [-hr]"
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
      warn "Stale master key"
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
      fatal "Illegal host name: $host"
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

  while read -ra line; do
    local host="${line[0]}"

    if ! store_secrets "$TMP/secrets/$host" "$TMP/store" "$(< "$TMP/store/keys/$host")" "keys/$host" "${line[@]:1}"; then
      warn "Illegal ACL for host '$host', store might be incomplete."
    fi
  done < "$TMP/store/ACL"

  rm -rf secrets
  mv "$TMP/secrets" .
  chown -R --reference . secrets
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
