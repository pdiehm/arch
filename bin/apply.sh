#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

if ((UID != 0)); then fatal "This script must be run as root"; fi
if ! resolve_host "${1:?Host name required}"; then fatal "Host '$1' not found"; fi

trap cleanup EXIT
TMP="$(mktemp -d)"
chmod 700 "$TMP"

PHASE=""
STAGE=0
declare -A OPTS=()

cleanup() {
  if mountpoint --quiet "$TMP/boot"; then umount --recursive "$TMP/boot"; fi
  if mountpoint --quiet "$TMP/root"; then umount --recursive "$TMP/root"; fi
  rm -rf --one-file-system "$TMP"
}

command_not_found_handle() {
  if [[ $PHASE == declare ]]; then return; fi
  error "Command not found: '$1'"
}

# error <message>
error() {
  echo "[ERROR] $*" >&2

  for ((src = 0; src < ${#FUNCNAME[@]} - 1; src++)); do
    if [[ ${BASH_SOURCE[src+1]} == "$0" ]]; then continue; fi
    echo "  at ${BASH_SOURCE[src+1]}:${BASH_LINENO[src]} (${FUNCNAME[src]})" >&2
  done

  kill "$$"
}

# resolve <path>
resolve() {
  local path="$1"

  if [[ $path == - ]]; then
    printf /dev/stdin
  elif [[ $path == ./* ]]; then
    path="$(dirname "$MODULE")/${path#./}"
    printf "%s" "${path#./}"
  else
    printf "%s" "$path"
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

# option [-am] [-d default] <name>
# option [-a] <name> <value>
# option <name> <key> <value>
option() {
  local OPTIND OPTARG opt
  local array=0 map=0 default=""

  while getopts "amd:" opt; do
    case "$opt" in
      a) array=1 ;;
      m) map=1 ;;
      d) default="$OPTARG" ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  if ((array + map > 1)); then error "Options '-a' and '-m' are mutually exclusive"; fi
  if [[ -n $default ]] && ((array + map > 0)); then error "Option '-d' cannot be used with '-a' or '-m'"; fi

  if (($# == 1)); then
    local name="OPT_${1^^}"
    if [[ $PHASE != declare ]]; then return; fi

    if ((array)); then
      if [[ ${OPTS[$name]:-array} != array ]]; then error "Option '$1' redeclared as different type"; fi

      OPTS[$name]="array"
      declare -ag "$name=()"
    elif ((map)); then
      if [[ ${OPTS[$name]:-map} != map ]]; then error "Option '$1' redeclared as different type"; fi

      OPTS[$name]="map"
      declare -Ag "$name=()"
    else
      if [[ ${OPTS[$name]:-string} != string ]]; then error "Option '$1' redeclared as different type"; fi

      OPTS[$name]="string"
      declare -g "$name=$default"
    fi
  elif (($# == 2)); then
    local name="OPT_${1^^}" value="$2"
    if [[ $PHASE != define ]]; then return; fi
    if ((map)); then error "Option '-m' can only be used for declaration"; fi
    if [[ -n $default ]]; then error "Option '-d' can only be used for declaration"; fi

    local type="${OPTS[$name]:-null}"
    local -n ref="$name"

    if [[ $type == string ]]; then
      if ((array)); then ref+="${ref:+ }$value"; else ref="$value"; fi
    elif [[ $type == array ]]; then
      if ((array)); then ref+=("$value"); else ref=("$value"); fi
    elif [[ $type == map ]]; then
      error "Setting map option requires key and value"
    else
      error "Setting unknown option '$1'"
    fi
  elif (($# == 3)); then
    local name="OPT_${1^^}" key="$2" value="$3"
    if [[ $PHASE != define ]]; then return; fi
    if ((array)); then error "Cannot append to map entries"; fi
    if ((map)); then error "Option '-m' can only be used for declaration"; fi
    if [[ -n $default ]]; then error "Option '-d' can only be used for declaration"; fi

    local type="${OPTS[$name]:-null}"
    local -n map="$name"

    if [[ $type == map ]]; then
      # shellcheck disable=SC2004
      map[$key]="$value"
    elif [[ $type != null ]]; then
      error "Setting key value pair is only valid for map options"
    else
      error "Setting unknown option '$1'"
    fi
  else
    error "Invalid arguments"
  fi
}

# run <command> ...
run() {
  if [[ $PHASE != build ]]; then return; fi

  printf "%s\n" "${*@Q}" >> "$TMP/stages/$STAGE/build.sh"
  sha <<< "$*" >> "$TMP/stages/$STAGE/hash"
}

# use [path]
use() {
  local path="${1:--}"
  if [[ $PHASE != build ]]; then return; fi

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

  printf "%s" "${target/#"$TMP/stages/$STAGE"//stage}"
}

# secret [-fq] <name>
secret() {
  local OPTIND OPTARG opt
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
      printf "%s" "$value" | use
    elif ((!query)); then
      printf "%s" "$value"
    fi

    return
  done < "$TMP/secrets"

  if ((query)); then return 1; fi
  error "Secret '$name' not found"
}

if [[ ! -f secrets/$HOST_NAME ]]; then
  fatal "No secrets for host '$HOST_NAME'"
fi

if [[ -f /var/lib/syscfg/key ]]; then
  if ! load_secrets "secrets/$HOST_NAME" "$TMP/secrets" "$(< /var/lib/syscfg/key)"; then
    warn "Stale host key"
  fi
fi

if [[ ! -f $TMP/secrets ]]; then
  if [[ -f /var/lib/syscfg/master ]]; then
    if ! load_secrets secrets/master "$TMP/master" "$(< /var/lib/syscfg/master)"; then
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
    if [[ $key != keys/$HOST_NAME ]]; then continue; fi

    if ! load_secrets "secrets/$HOST_NAME" "$TMP/secrets" "$value"; then
      fatal "Incorrect host key"
    fi

    break
  done < "$TMP/master"

  if [[ ! -f $TMP/master ]]; then fatal "No key for host '$HOST_NAME'"; fi
  rm "$TMP/master"
fi

mkdir -p "$TMP/stages/$STAGE/res"
PHASE="declare" import main
PHASE="define" import main
PHASE="build" import main

mount --mkdir --label root "$TMP/root"
BUILD="$TMP/root/build"
HASH="$(sha base)"

btrfs property set "$TMP/root" compression zstd
if [[ ! -d $TMP/root/images ]]; then mkdir "$TMP/root/images"; fi
if [[ ! -d $TMP/root/perm ]]; then btrfs subvolume create "$TMP/root/perm"; fi
if [[ ! -d $TMP/root/pkgs ]]; then btrfs subvolume create "$TMP/root/pkgs"; fi
if [[ -d $BUILD ]]; then btrfs subvolume delete --recursive "$BUILD"; fi

if [[ ! -d $TMP/root/images/$HASH ]]; then
  btrfs subvolume create "$BUILD"
  mount --bind "$BUILD" "$BUILD"
  mount --mkdir --bind "$TMP/root/pkgs" "$BUILD/var/cache/pacman/pkg"

  pacstrap -G "$BUILD"
  arch-chroot "$BUILD" bash -c "pacman-key --init && pacman-key --populate"
  arch-chroot "$BUILD" mkdir -m 1777 /perm

  umount --recursive "$BUILD"
  mv "$BUILD" "$TMP/root/images/$HASH"
fi

touch "$TMP/root/images/$HASH"
for ((stage = 0; stage < STAGE; stage++)); do
  hash="$(sha "$HASH->$(sha < "$TMP/stages/$stage/hash")")"

  if [[ ! -d $TMP/root/images/$hash ]]; then
    btrfs subvolume snapshot "$TMP/root/images/$HASH" "$BUILD"
    mount --bind "$BUILD" "$BUILD"
    mount --bind "$TMP/root/pkgs" "$BUILD/var/cache/pacman/pkg"
    mount --mkdir --bind "$TMP/stages/$stage" "$BUILD/stage"

    arch-chroot "$BUILD" bash -eu /stage/build.sh
    umount --recursive "$BUILD"
    rmdir "$BUILD/stage"
    mv "$BUILD" "$TMP/root/images/$hash"
  fi

  HASH="$hash"
  touch "$TMP/root/images/$HASH"
done

rm -f "$TMP/root/latest"
ln -s "images/$HASH" "$TMP/root/latest"
find "$TMP/root/images" -mindepth 1 -maxdepth 1 -mtime +1 -exec btrfs subvolume delete --recursive "{}" +

mount --mkdir --label BOOT "$TMP/boot"
rm -rf "${TMP:?}/boot"/*
cp -r "$TMP/root/latest/boot/." "$TMP/boot"

for path in "$TMP/root/latest/perm"/*; do
  target="$TMP/root/perm/${path##*/}"
  if [[ ! -e $target ]]; then cp -a "$path" "$target"; fi
  touch "$target"
done

find "$TMP/root/perm" -mindepth 1 -maxdepth 1 -mtime +1 -exec rm -rf "{}" +
