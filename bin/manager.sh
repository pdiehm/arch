#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

as_root() {
  if ((UID)); then
    exec sudo "$0" "$@"
  else
    "$@"
  fi
}

overlay() {
  trap 'unmount "$TMP/boot"; unmount "$TMP/root"; rm -rf --one-file-system "$TMP"' EXIT
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

  HASH="$(readlink "$TMP/root/base")"
  HASH="$(sha "${HASH##*/}++")"
  unmount "$TMP/root/build"

  if [[ -d $TMP/root/imgs/$HASH ]]; then btrfs subvolume delete --recursive "$TMP/root/imgs/$HASH"; fi
  mv "$TMP/root/build" "$TMP/root/imgs/$HASH"

  rm -f "$TMP/root/base"
  ln -s "imgs/$HASH" "$TMP/root/base"

  mount --mkdir --label BOOT "$TMP/boot"
  find "$TMP/boot" -mindepth 1 -delete
  cp -r "$TMP/root/base/boot/." "$TMP/boot"
}

help() {
  echo "Usage: sm <command> [args ...]"
  echo
  echo "Commands:"
  echo "  help                     Print this help message"
  echo "  edit                     Open editor in configuration repository"
  echo "  fix                      Edit latest image"
  echo "  rebuild [-hbcn] [host]   Rebuild system configuration"
  echo "  secrets [-hr]            Manage secrets"
  echo "  sync                     Sync configuration repository"
  echo "  upgrade                  Upgrade system"
}

edit() {
  exec "$EDITOR" .
}

fix() {
  overlay bash
}

rebuild() {
  HELP=0

  while getopts "hbcn" opt; do
    case "$opt" in
      h) HELP=1 ;;
      b) export SM_BREAK=1 ;;
      c) export SM_CLEAN=1 ;;
      n) export SM_DRY=1 ;;
      *) fatal "Illegal option" ;;
    esac
  done

  if ((HELP)); then
    echo "Usage: sm rebuild [-hcbn] [host]"
    echo
    echo "Options:"
    echo "  -h   Print this help message"
    echo "  -b   Break after evaluation"
    echo "  -c   Ignore cached images"
    echo "  -n   Skip activation"
    return
  fi

  shift "$((OPTIND - 1))"
  exec bin/build.sh "${@:-$HOSTNAME}"
}

secrets() {
  HELP=0
  ROTATE=0

  while getopts "hr" opt; do
    case "$opt" in
      h) HELP=1 ;;
      r) ROTATE=1 ;;
      *) fatal "Illegal option" ;;
    esac
  done

  if ((HELP)); then
    echo "Usage: sm secrets [-hr]"
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

  if [[ -f secrets/master && -f /usr/local/lib/syscfg/master ]]; then
    if ! load_secrets secrets/master "$TMP/store" "$(< /usr/local/lib/syscfg/master)"; then
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

  if ((ROTATE)); then
    read -rsp "Enter new master password: "
    echo

    find "$TMP/store/keys" -mindepth 1 -delete
    sha "$REPLY" > "$TMP/store/keys/master"
  fi

  while read -r host _; do
    if [[ $host == master || $host =~ [^a-zA-Z0-9-] ]]; then
      fatal "Illegal host name: $host"
    elif [[ ! -f $TMP/store/keys/$host ]]; then
      head -c 64 /dev/urandom | sha > "$TMP/keys/$host"
    fi
  done < "$TMP/store/ACL"

  mkdir "$TMP/secrets"
  store_secrets "$TMP/secrets/master" "$TMP/store" "$(< "$TMP/store/keys/master")" .

  while read -r host spec; do
    read -ra spec <<< "$spec"

    if ! store_secrets "$TMP/secrets/$host" "$TMP/store" "$(< "$TMP/store/keys/$host")" "keys/$host" "${spec[@]}"; then
      warn "Illegal ACL for host '$host', store might be incomplete."
    fi
  done < "$TMP/store/ACL"

  rm -rf secrets
  mv "$TMP/secrets" .
  chown -R --reference . secrets
}

sync() {
  git pull

  if (($(git rev-list --count "@{upstream}.."))); then
    read -rp "Push local commits? [y/N] "
    if [[ $REPLY == y ]]; then git push; fi
  fi
}

upgrade() {
  overlay bash -eu /usr/local/lib/syscfg/upgrade.sh
}

case "${1:-help}" in
  help) help ;;
  edit | sync) "$@" ;;
  fix | rebuild | secrets | upgrade) as_root "$@" ;;
  *) fatal "Illegal command: $1" ;;
esac
