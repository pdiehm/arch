#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

help() {
  echo "Usage: $0 <command> [args ...]"
  echo
  echo "Commands:"
  echo "  help      Print this help message"
  echo "  rebuild   Rebuild the system configuration for the current host"
  echo "  secrets   Manage secrets"
  echo "  sync      Sync configuration repository"
  echo "  upgrade   Upgrade the current configuration"
}

rebuild() {
  sudo bin/apply.sh "$HOSTNAME"
}

secrets() {
  if ((UID != 0)); then exec sudo "$0" secrets "$@"; fi

  trap 'rm -rf "$TMP"' EXIT
  TMP="$(mktemp -d)"
  chmod 700 "$TMP"

  declare -A SECRETS=()
  if [[ -f secrets/master && -f /var/lib/syscfg/master ]]; then
    SECRETS[keys/master]="$(< /var/lib/syscfg/master)"

    if ! load_secrets secrets/master "$TMP/secrets" "${SECRETS[keys/master]}"; then
      warn "Stale master password"
    fi
  fi

  if [[ ! -f $TMP/secrets ]]; then
    read -rsp "Enter master password: " read
    echo

    SECRETS[keys/master]="$(encode_secret "$read")"
    if [[ -f secrets/master ]]; then
      if ! load_secrets secrets/master "$TMP/secrets" "${SECRETS[keys/master]}"; then
        fatal "Incorrect master password"
      fi
    fi
  fi

  if [[ -f $TMP/secrets ]]; then
    while read -r key value; do SECRETS[$key]="$value"; done < "$TMP/secrets"
    rm "$TMP/secrets"
  fi

  declare -A ACCESS=()
  HOSTS=()

  for host in secrets/*; do
    host="${host##*/}"

    if [[ $host == master ]]; then continue; fi
    HOSTS+=("$host")

    if [[ -z ${SECRETS[keys/$host]+x} ]]; then
      warn "No key for host '$host', skipping..."
      continue
    fi

    if ! load_secrets "secrets/$host" "$TMP/secrets" "${SECRETS[keys/$host]}"; then
      warn "Failed to load secrets for host '$host', skipping..."
      continue
    fi

    while read -r key value; do
      if [[ -z ${SECRETS[$key]+x} ]]; then
        warn "Secret '$key' for host '$host' not in master, skipping..."
        continue
      fi

      ACCESS[$key]+="$host "
    done < "$TMP/secrets"

    rm "$TMP/secrets"
  done

  printf "HOSTS %s\n" "${HOSTS[*]}" > "$TMP/edit"
  printf "MASTER %s\n" "${ACCESS[keys/master]:-}" >> "$TMP/edit"

  for key in "${!SECRETS[@]}"; do
    if [[ $key == keys/* ]]; then continue; fi
    printf "\nSECRET %s %s\n" "$key" "${ACCESS[$key]:-}" >> "$TMP/edit"
    printf "%s\nEOF\n" "$(decode_secret "${SECRETS[$key]}")" >> "$TMP/edit"
  done

  if ! "$EDITOR" "$TMP/edit"; then
    warn "Editor exited with non-zero status, aborting..."
    return
  fi

  mkdir "$TMP/secrets"
  printf "keys/master %s\n" "${SECRETS[keys/master]}" > "$TMP/secrets/master"

  NAME=""
  HOSTS=()
  VALUE=()

  while read -r line; do
    if [[ -n $NAME && $line != EOF ]]; then
      VALUE+=("$line")
      continue
    fi

    read -ra cmd <<< "$line"
    if ((${#cmd[@]} == 0)); then continue; fi

    case "${cmd[0]}" in
      HOSTS)
        for host in "${cmd[@]:1}"; do
          if [[ $host == master ]]; then fatal "Host name 'master' is reserved"; fi
          if [[ $host =~ [^a-zA-Z0-9-] ]]; then fatal "Host name '$host' contains invalid characters"; fi
          if [[ -f $TMP/secrets/$host ]]; then fatal "Duplicate host name '$host'"; fi

          if [[ -z ${SECRETS[keys/$host]+x} ]]; then
            SECRETS[keys/$host]="$(head -c 32 /dev/urandom | encode_secret)"
          fi

          printf "keys/%s %s\n" "$host" "${SECRETS[keys/$host]}" >> "$TMP/secrets/master"
          printf "keys/%s %s\n" "$host" "${SECRETS[keys/$host]}" > "$TMP/secrets/$host"
        done
        ;;

      MASTER)
        for host in "${cmd[@]:1}"; do
          if [[ ! -f $TMP/secrets/$host ]]; then fatal "Host '$host' not in hosts list"; fi
          printf "keys/master %s\n" "${SECRETS[keys/master]}" >> "$TMP/secrets/$host"
        done
        ;;

      SECRET)
        if ((${#cmd[@]} < 2)); then fatal "SECRET command requires a name"; fi

        NAME="${cmd[1]}"
        if [[ $NAME == keys/* ]]; then fatal "Secret name cannot start with 'keys/'"; fi
        if [[ $NAME =~ [^a-zA-Z0-9/-] ]]; then fatal "Secret name '$NAME' contains invalid characters"; fi

        HOSTS=("${cmd[@]:2}")
        VALUE=()
        ;;

      EOF)
        if [[ -z $NAME ]]; then fatal "Unexpected EOF"; fi
        value="$(IFS=$'\n' && encode_secret "${VALUE[*]}")"

        for host in master "${HOSTS[@]}"; do
          if [[ ! -f $TMP/secrets/$host ]]; then fatal "Host '$host' not in hosts list"; fi
          printf "%s %s\n" "$NAME" "$value" >> "$TMP/secrets/$host"
        done

        NAME=""
        ;;

      *) fatal "Unknown command '${cmd[0]}'" ;;
    esac
  done < "$TMP/edit"

  if [[ -n $NAME ]]; then
    fatal "Unexpected end of file while reading secret '$NAME'"
  fi

  rm -rf secrets
  mkdir -m 700 secrets

  for host in "$TMP/secrets"/*; do
    host="${host##*/}"
    save_secrets "$TMP/secrets/$host" "secrets/$host" "${SECRETS[keys/$host]}"
  done

  chmod 400 secrets/*
  chown -R "$(stat -c "%u:%g" .)" secrets
}

sync() {
  git pull
  git push
}

upgrade() {
  if ((UID != 0)); then exec sudo "$0" upgrade "$@"; fi

  trap 'umount "$TMP/boot"; umount --recursive "$TMP/root"; rm -rf --one-file-system "$TMP"' EXIT
  TMP="$(mktemp -d)"
  chmod 700 "$TMP"

  mount --mkdir --label root "$TMP/root"
  HASH="$(readlink "$TMP/root/latest")"
  HASH="$(sha "${HASH##*/}++")"

  BUILD="$TMP/root/build"
  if [[ -d $BUILD ]]; then btrfs subvolume delete --recursive "$BUILD"; fi

  btrfs subvolume snapshot "$TMP/root/latest" "$BUILD"
  mount --bind "$BUILD" "$BUILD"
  mount --bind "$TMP/root/pkgs" "$BUILD/var/cache/pacman/pkg"
  arch-chroot "$BUILD" /bin/bash -eu /var/lib/syscfg/upgrade.sh

  touch "$BUILD"
  umount "$BUILD"
  mv "$BUILD" "$TMP/root/images/$HASH"

  rm -f "$TMP/root/latest"
  ln -s "images/$HASH" "$TMP/root/latest"

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
  rebuild) rebuild "${@:2}" ;;
  secrets) secrets "${@:2}" ;;
  sync) sync "${@:2}" ;;
  upgrade) upgrade "${@:2}" ;;
  *) fatal "Unknown command '$1'" ;;
esac
