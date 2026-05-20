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
      *) fatal "Invalid option: -$opt" ;;
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
      *) fatal "Invalid option: -$opt" ;;
    esac
  done

  if ((help)); then
    echo "Usage: manager.sh secrets [-hr]"
    echo
    echo "Options:"
    echo "  -h   Print this help message"
    echo "  -r   Rotate master password"
    return
  fi

  trap 'rm -rf "$TMP"' EXIT
  TMP="$(mktemp -d)"
  chmod 700 "$TMP"

  local -A secrets=()
  local keys=()

  if [[ -f secrets/master && -f /var/local/syscfg/master ]]; then
    secrets["keys/master"]="$(< /var/local/syscfg/master)"
    if ! load_secrets secrets/master "$TMP/secrets" "${secrets["keys/master"]}"; then
      warn "Stale master password"
    fi
  fi

  if [[ ! -f $TMP/secrets ]]; then
    read -rsp "Enter master password: " read
    echo

    secrets["keys/master"]="$(encode_secret "$read")"
    if [[ -f secrets/master ]]; then
      if ! load_secrets secrets/master "$TMP/secrets" "${secrets["keys/master"]}"; then
        fatal "Incorrect master password"
      fi
    fi
  fi

  if [[ -f $TMP/secrets ]]; then
    while read -r key value; do
      secrets[$key]="$value"
      keys+=("$key")
    done < "$TMP/secrets"

    rm "$TMP/secrets"
  fi

  if ((rotate)); then
    read -rsp "Enter new master password: " read
    echo
    secrets["keys/master"]="$(encode_secret "$read")"
  fi

  local -A access=()
  local hosts=()

  for host in secrets/*; do
    host="${host##*/}"
    if [[ $host == master ]]; then continue; fi

    if [[ -z ${secrets["keys/$host"]:+x} ]]; then
      warn "No key for host '$host', skipping..."
      continue
    fi

    if ! load_secrets "secrets/$host" "$TMP/secrets" "${secrets["keys/$host"]}"; then
      warn "Failed to load secrets for host '$host', skipping..."
      continue
    fi

    while read -r key value; do
      if [[ -z ${secrets[$key]:+x} ]]; then
        warn "Secret '$key' for host '$host' not in master, skipping..."
      else
        access[$key]+="$host "
      fi
    done < "$TMP/secrets"

    hosts+=("$host")
    rm "$TMP/secrets"
  done

  echo "HOSTS ${hosts[*]}" > "$TMP/edit"
  echo "MASTER ${access["keys/master"]:-}" >> "$TMP/edit"

  for key in "${keys[@]}"; do
    if [[ $key == keys/* ]]; then continue; fi
    printf "\nSECRET %s %s\n" "$key" "${access[$key]:-}" >> "$TMP/edit"
    printf "%s\nEOF\n" "$(decode_secret "${secrets[$key]}")" >> "$TMP/edit"
  done

  while true; do
    if ! "${EDITOR:-vim}" "$TMP/edit"; then
      fatal "Editor exited with non-zero status, aborting..."
    fi

    rm -rf "$TMP/secrets"
    mkdir "$TMP/secrets"
    echo "keys/master ${secrets["keys/master"]}" > "$TMP/secrets/master"

    local error="" name="" hosts=() value=()
    while read -r line; do
      if [[ -n $name && $line != EOF ]]; then
        value+=("$line")
        continue
      fi

      read -ra cmd <<< "$line"
      if ((${#cmd[@]} == 0)); then continue; fi

      case "${cmd[0]}" in
        HOSTS)
          for host in "${cmd[@]:1}"; do
            if [[ $host == master ]]; then
              error="Host name 'master' is reserved"
            elif [[ $host =~ [^a-zA-Z0-9-] ]]; then
              error="Host name '$host' contains invalid characters"
            elif [[ -f $TMP/secrets/$host ]]; then
              error="Duplicate host name '$host'"
            else
              if [[ -z ${secrets["keys/$host"]:+x} ]]; then
                secrets["keys/$host"]="$(head -c 32 /dev/urandom | encode_secret)"
              fi

              echo "keys/$host ${secrets["keys/$host"]}" >> "$TMP/secrets/master"
              echo "keys/$host ${secrets["keys/$host"]}" > "$TMP/secrets/$host"
            fi
          done
          ;;

        MASTER)
          for host in "${cmd[@]:1}"; do
            if [[ ! -f $TMP/secrets/$host ]]; then
              error="Host '$host' not in hosts list"
            else
              echo "keys/master ${secrets["keys/master"]}" >> "$TMP/secrets/$host"
            fi
          done
          ;;

        SECRET)
          name="${cmd[1]:-}"

          if [[ -z $name ]]; then
            error="SECRET command requires a name"
          elif [[ $name == keys/* ]]; then
            error="Secret name cannot start with 'keys/'"
          elif [[ $name =~ [^a-zA-Z0-9/_-] ]]; then
            error="Secret name '$name' contains invalid characters"
          else
            hosts=("${cmd[@]:2}")
            value=()
          fi
          ;;

        EOF)
          if [[ -z $name ]]; then
            error="Unexpected EOF"
          else
            text="$(IFS=$'\n' && encode_secret "${value[*]}")"

            for host in "master" "${hosts[@]}"; do
              if [[ ! -f $TMP/secrets/$host ]]; then
                error="Host '$host' not in hosts list"
              else
                echo "$name $text" >> "$TMP/secrets/$host"
              fi
            done

            name=""
          fi
          ;;

        *) error="Unknown command: ${cmd[0]}" ;;
      esac

      if [[ -n $error ]]; then
        break
      fi
    done < "$TMP/edit"

    if [[ -z $error ]]; then
      if [[ -n $name ]]; then
        error="Unexpected end of file while reading secret '$name'"
      else
        break
      fi
    fi

    warn "$error"
    read -rp "Press enter to continue..."
  done

  rm -rf secrets
  mkdir -m 700 secrets

  for host in "$TMP/secrets"/*; do
    host="${host##*/}"
    save_secrets "$TMP/secrets/$host" "secrets/$host" "${secrets["keys/$host"]}"
  done

  chmod 400 secrets/*
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
  *) fatal "Unknown command: $1" ;;
esac
