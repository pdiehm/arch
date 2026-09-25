#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$(realpath "$0")")/.."
source bin/lib.sh

STAGE=0

if ((UID)); then fatal "Not root"; fi
if (($# != 1)); then fatal "Usage: build.sh <host>"; fi
if ! load_host "$1"; then fatal "Unknown host: $1"; fi

trap 'unmount "$TMP/boot"; unmount "$TMP/root"; printf "\e[s\e[r\e[u"; rm -rf --one-file-system "$TMP"' EXIT
TMP="$(mktemp -d)"
chmod 700 "$TMP"

# error <message> ...
error() {
  echo -e "[\e[31mERROR\e[m] $*" >&2

  for ((i = 0; i < ${#FUNCNAME[@]} - 1; i++)); do
    if [[ ${BASH_SOURCE[i + 1]} == "$0" ]]; then continue; fi
    echo "  at ${BASH_SOURCE[i + 1]}:${BASH_LINENO[i]} (${FUNCNAME[i]})" >&2
  done

  kill "$$"
}

# resolve <path>
resolve() {
  local path="$1"

  if [[ $path != ./* ]]; then
    echo "$path"
  elif [[ $MODULE != */* ]]; then
    echo "${path#./}"
  else
    echo "${MODULE%/*}/${path#./}"
  fi
}

# import <path>
import() {
  local path="$1" mod
  path="$(resolve "$path")"
  if [[ $path == /* ]]; then error "Absolute path: $path"; fi

  for mod in "$path" "$path.sh" "$path/main.sh"; do
    if [[ ! -f $mod ]]; then continue; fi
    if [[ -f $TMP/stages/$STAGE/build.sh ]]; then mkdir "$TMP/stages/$((++STAGE))"; fi

    if ((DRY)); then echo "Loading module $mod"; else echo "Evaluating module $mod"; fi
    echo "$mod" > "$TMP/stages/$STAGE/module"

    # shellcheck disable=SC1090
    MODULE="$mod" source "$mod"
    echo "$mod" > "$TMP/stages/$STAGE/module"

    if [[ -f $TMP/stages/$STAGE/build.sh ]]; then mkdir "$TMP/stages/$((++STAGE))"; fi
    return
  done

  error "Not found: $path"
}

# use [path]
use() {
  local path="${1:-/dev/stdin}" hash
  path="$(resolve "$path")"
  if ((DRY)); then return; fi

  if [[ $path == /* && $path != /dev/stdin && $path != $TMP/* ]]; then
    error "Absolute path: $path"
  elif [[ ! -e $path ]]; then
    error "No such file or directory: $path"
  fi

  cp "$path" "$TMP/res"
  hash="$(sha < "$TMP/res")"
  if [[ $path == /dev/stdin ]]; then chmod 444 "$TMP/res"; fi

  mv "$TMP/res" "$TMP/stages/$STAGE/$hash"
  echo "$hash" >> "$TMP/stages/$STAGE/hash"
  echo "/stage/$hash"
}

# secret [-fq] <name>
#   -f   return path to file
#   -q   query secret existence
secret() {
  local OPTIND OPTARG opt
  local file=0 query=0

  while getopts "fq" opt; do
    case "$opt" in
      f) file=1 ;;
      q) query=1 ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local name="$1"
  if ((file + query > 1)); then error "Options '-f' and '-q' are mutually exclusive"; fi

  if [[ -f $TMP/secrets/$name ]]; then
    if ((query)); then return; fi
    if ((file)); then use "$TMP/secrets/$name"; else cat "$TMP/secrets/$name"; fi
  else
    if ((query)); then return 1; fi
    error "Unknown secret: $name"
  fi
}

# run [-u] <command> ...
#   -u   as user in home directory
run() {
  local OPTIND OPTARG opt
  local user=0

  while getopts "u" opt; do
    case "$opt" in
      u) user=1 ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local command="${*@Q}"
  if ((DRY)); then return; fi

  if ((user)); then command="sudo -Eu pascal env -C /home/pascal $command"; fi
  echo "$command" >> "$TMP/stages/$STAGE/build.sh"
  sha <<< "$command" >> "$TMP/stages/$STAGE/hash"
}

# script [-u] [path [args ...]]
#   -u   as user in home directory
script() {
  local OPTIND OPTARG opt
  local user=""

  while getopts "u" opt; do
    case "$opt" in
      u) user="-u" ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local path="${1:-/dev/stdin}" args=("${@:2}")

  path="$(use "$path")"
  run $user bash -eu "$path" "${args[@]}"
}

# write [-auvx] [-m mode] [-o owner] <path> [content ...]
#   -a   append
#   -u   as user in home directory
#   -v   substitute variables
#   -x   set executable
#   -m   change mode
#   -o   change owner
write() {
  local OPTIND OPTARG opt
  local append=0 user="" vars=0 exec=0 mode="" owner=""

  while getopts "auvxm:o:" opt; do
    case "$opt" in
      a) append=1 ;;
      u) user="-u" ;;
      v) vars=1 ;;
      x) exec=1 ;;
      m) mode="$OPTARG" ;;
      o) owner="$OPTARG" ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local path="$1" lines=("${@:2}") src cmd

  if ((${#lines[@]})); then src="$(printf "%s\n" "${lines[@]}" | use)"; else src="$(use)"; fi
  if ((vars)); then cmd="sed \"\$VARS\" ${src@Q}"; else cmd="cat ${src@Q}"; fi
  if ((append)); then cmd+=" >> ${path@Q}"; else cmd+=" > ${path@Q}"; fi

  run $user mkdir -p "$(dirname "$path")"
  run $user sh -c "$cmd"
  if [[ $owner ]]; then run $user chown "$owner" "$path"; fi
  if [[ $mode ]]; then run $user chmod "$mode" "$path"; fi
  if ((exec)); then run $user chmod +x "$path"; fi
  if ((vars)); then run unset VARS; fi
}

# copy [-suvx] [-m mode] [-o owner] <src> <dst>
#   -s   interpret src as secret name
#   -u   as user in home directory
#   -v   substitute variables
#   -x   set executable
#   -m   change mode
#   -o   change owner
copy() {
  local OPTIND OPTARG opt
  local secret=0 user="" vars=0 exec=0 mode="" owner=""

  while getopts "suvxm:o:" opt; do
    case "$opt" in
      s) secret=1 ;;
      u) user="-u" ;;
      v) vars=1 ;;
      x) exec=1 ;;
      m) mode="$OPTARG" ;;
      o) owner="$OPTARG" ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local src="$1" dst="$2"

  if ((secret)); then
    mode="${mode:-400}"
    src="$(secret -f "$src")"
  else
    src="$(use "$src")"
  fi

  run $user mkdir -p "$(dirname "$dst")"
  if ((vars)); then run $user sh -c "sed \"\$VARS\" ${src@Q} > ${dst@Q}"; else run $user cp "$src" "$dst"; fi
  if [[ $owner ]]; then run $user chown "$owner" "$dst"; fi
  if [[ $mode ]]; then run $user chmod "$mode" "$dst"; fi
  if ((exec)); then run $user chmod +x "$dst"; fi
  if ((vars)); then run unset VARS; fi
}

# symlink [-u] <src> <dst>
#   -u   as user in home directory
symlink() {
  local OPTIND OPTARG opt
  local user=""

  while getopts "u" opt; do
    case "$opt" in
      u) user="-u" ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local src="$1" dst="$2"
  if [[ $src != /* ]]; then src="/home/pascal/.config/syscfg/$(resolve "$src")"; fi

  run $user sh -c "if [[ -e ${dst@Q} ]]; then echo 'Cannot create symlink' ${dst@Q} '- File exists' >&2; exit 1; fi"
  run $user mkdir -p "$(dirname "$dst")"
  run $user ln -s "$src" "$dst"
}

# persist [-fu] [-m mode] <path>
#   -f   persist file
#   -u   as user in home directory
#   -m   change mode if created
persist() {
  local OPTIND OPTARG opt
  local file=0 user="" mode=""

  while getopts "fum:" opt; do
    case "$opt" in
      f) file=1 ;;
      u) user="-u" ;;
      m) mode="$OPTARG" ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local path="$1"
  if [[ $path =~ ([[:space:]]|\\) ]]; then error "Invalid path: $path"; fi

  if [[ $path != /* ]]; then
    if [[ $user ]]; then
      path="/home/pascal/$path"
    else
      path="/$path"
    fi
  fi

  local target="${path//[^a-zA-Z0-9.-]/_}"
  target="/keep/${target:1}"

  run $user sh -c "if [[ -e ${target@Q} ]]; then echo 'Cannot persist' ${path@Q} '- Already persisted' >&2; exit 1; fi"
  run $user sh -c "if [[ -e ${path@Q} ]]; then mv ${path@Q} ${target@Q}; fi"
  run $user mkdir -p "$(dirname "$path")"

  if ((file)); then run $user touch "$path" "$target"; else run $user mkdir -p "$path" "$target"; fi
  if [[ $mode ]]; then run $user chmod "$mode" "$target"; fi
  write -a /etc/fstab "$target $path none bind 0 0"
}

# var <name> <value>
var() {
  local name="$1" value="$2"
  run export "VARS+=s|@$name@|$value|g;"
}

# conf [-de] <path> <name> ...
#   -d   disable options
#   -e   enable options
conf() {
  local OPTIND OPTARG opt
  local disable=0 enable=0

  while getopts "de" opt; do
    case "$opt" in
      d) disable=1 ;;
      e) enable=1 ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local path="$1" names=("${@:2}") name
  if ((disable + enable > 1)); then error "Options '-d' and '-e' are mutually exclusive"; fi

  for name in "${names[@]}"; do
    if ((disable)); then
      run sed -Ei "s|^#?\s*($name)\b|#\1|" "$path"
    elif ((enable)); then
      run sed -Ei "s|^#?\s*($name)\b|\1|" "$path"
    else
      run sed -Ei "s|^#?\s*${name%%=*}\s*=.*|$name|" "$path"
    fi
  done
}

# package <name> ...
package() {
  run pacman --noconfirm --sync --refresh --sysupgrade --needed "$@"
}

# upgrade [-u] [command ...]
#   -u   as user in home directory
upgrade() {
  local OPTIND OPTARG opt
  local user=0

  while getopts "u" opt; do
    case "$opt" in
      u) user=1 ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local command="${*@Q}"

  if [[ ! $command ]]; then
    write -ax /usr/local/lib/syscfg/upgrade.sh
  elif ((user)); then
    write -ax /usr/local/lib/syscfg/upgrade.sh "sudo -u pascal env -C /home/pascal $command"
  else
    write -ax /usr/local/lib/syscfg/upgrade.sh "$command"
  fi
}

# systemd [-eu] [-t target] <unit> ...
#   -e   enable units
#   -u   in user manager
#   -t   for target
#
# systemd [-du] <unit> ...
#   -d   disable units
#   -u   in user manager
#
# systemd [-mu] <unit> ...
#   -m   mask units
#   -u   in user manager
#
# systemd [-iu] <unit> ...
#   -i   install units
#   -u   in user manager
systemd() {
  local OPTIND OPTARG opt
  local enable=0 disable=0 mask=0 install=0 user=0 target=""

  while getopts "edmiut:" opt; do
    case "$opt" in
      e) enable=1 ;;
      d) disable=1 ;;
      m) mask=1 ;;
      i) install=1 ;;
      u) user=1 ;;
      t) target="$OPTARG" ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local unit

  if ((enable + disable + mask + install != 1 + (enable && install))); then error "Exactly one of '-e', '-d', '-m', '-i' or '-ie' is required"; fi
  if [[ $target ]] && ((enable + user != 2)); then error "Option '-t' requires '-e' and '-u'"; fi
  target="${target:-default.target}"

  if ((enable)); then
    if ((user)); then
      for unit; do
        if [[ $unit == /* ]]; then
          symlink -u "$unit" ".config/systemd/user/$target.wants/${unit##*/}"
        else
          if ((install)); then systemd -iu "$unit"; fi
          symlink -u "/home/pascal/.config/systemd/user/$unit" ".config/systemd/user/$target.wants/$unit"
        fi
      done
    else
      if ((install)); then systemd -i "$@"; fi
      run systemctl enable "$@"
    fi
  elif ((disable)); then
    if ((user)); then
      run -u sh -c "rm -f .config/systemd/user/*.wants/${unit@Q}"
    else
      run systemctl disable "$@"
    fi
  elif ((mask)); then
    if ((user)); then
      for unit; do symlink -u /dev/null ".config/systemd/user/$unit"; done
    else
      run systemctl mask "$@"
    fi
  elif ((install)); then
    if ((user)); then
      for unit; do copy -u "res/systemd/user/$unit" ".config/systemd/user/$unit"; done
    else
      for unit; do copy "res/systemd/system/$unit" "/etc/systemd/system/$unit"; done
    fi
  fi
}

# timer [-nu] <name> <time> <command> ...
#   -n   wait for network
#   -u   in user manager
timer() {
  local OPTIND OPTARG opt
  local network=0 user=0

  while getopts "nu" opt; do
    case "$opt" in
      n) network=1 ;;
      u) user=1 ;;
      *) error "Illegal option" ;;
    esac
  done

  shift "$((OPTIND - 1))"
  local name="$1" time="$2" command="$3" args=("${@:4}")
  local timer=("[Timer]" "OnCalendar=$time" "Persistent=true" "" "[Install]" "WantedBy=timers.target")

  local service=("[Service]" "Type=oneshot")
  if ((network)); then service+=('ExecStartPre=/bin/sh -c "until ping -c 1 1.1.1.1; do sleep 1; done"'); fi
  service+=("ExecStart=$command ${args[*]@Q}")

  if ((user)); then
    write -u ".config/systemd/user/$name.service" "${service[@]}"
    write -u ".config/systemd/user/$name.timer" "${timer[@]}"
    systemd -eut timers.target "$name.timer"
  else
    write "/etc/systemd/system/$name.service" "${service[@]}"
    write "/etc/systemd/system/$name.timer" "${timer[@]}"
    systemd -e "$name.timer"
  fi
}

mkdir "$TMP/secrets"
if [[ ! -f secrets/$HOST_NAME ]]; then fatal "No secrets for host"; fi

if [[ -f /usr/local/lib/syscfg/key ]]; then
  if ! load_secrets "secrets/$HOST_NAME" "$TMP/secrets" "$(< /usr/local/lib/syscfg/key)"; then
    warn "Stale host key"
  fi
fi

if [[ ! -f $TMP/secrets/keys/$HOST_NAME ]]; then
  mkdir "$TMP/master"

  if [[ -f /usr/local/lib/syscfg/master ]]; then
    if ! load_secrets secrets/master "$TMP/master" "$(< /usr/local/lib/syscfg/master)"; then
      warn "Stale master key"
    fi
  fi

  if [[ ! -f $TMP/master/ACL ]]; then
    read -rsp "Enter master password: "
    echo

    if ! load_secrets secrets/master "$TMP/master" "$(sha "$REPLY")"; then
      fatal "Incorrect master password"
    fi
  fi

  if [[ ! -f $TMP/master/keys/$HOST_NAME ]]; then
    fatal "No key for host"
  elif ! load_secrets "secrets/$HOST_NAME" "$TMP/secrets" "$(< "$TMP/master/keys/$HOST_NAME")"; then
    fatal "Incorrect host key"
  fi

  rm -rf "$TMP/master"
fi

mkdir -p "$TMP/stages/$STAGE"
DRY=1 import main
DRY=0 import main

if [[ ${SM_BREAK:+x} ]]; then
  if ! env -C "$TMP" bash; then
    fatal "Shell exited with non-zero status, aborting..."
  fi
fi

HASH="$(sha base)"
USED=("$HASH")

printf "\e[s\e[2r\e[H\e[K\e[1mBuilding system...\e[m\e[u\n"
mount --mkdir --label root "$TMP/root"

btrfs property set "$TMP/root" compression zstd
if [[ ! -d $TMP/root/imgs ]]; then mkdir "$TMP/root/imgs"; fi
if [[ ! -d $TMP/root/keep ]]; then btrfs subvolume create "$TMP/root/keep"; fi
if [[ ! -d $TMP/root/pkgs ]]; then btrfs subvolume create "$TMP/root/pkgs"; fi
if [[ -d $TMP/root/build ]]; then btrfs subvolume delete --recursive "$TMP/root/build"; fi

if [[ ${SM_CLEAN:+x} || ! -d $TMP/root/imgs/$HASH ]]; then
  printf "\e[s\e[H\e[K\e[1mInstalling base system...\e[m\e[u"
  btrfs subvolume create "$TMP/root/build"
  pacstrap -G "$TMP/root/build"

  if [[ -d $TMP/root/imgs/$HASH ]]; then btrfs subvolume delete --recursive "$TMP/root/imgs/$HASH"; fi
  mv "$TMP/root/build" "$TMP/root/imgs/$HASH"
fi

for ((stage = 0; stage < STAGE; stage++)); do
  hash="$(sha < "$TMP/stages/$stage/hash")"
  hash="$(sha "$HASH+$hash")"

  if [[ ${SM_CLEAN:+x} || ! -d $TMP/root/imgs/$hash ]]; then
    printf "\e[s\e[H\e[K\e[1mStage %d of %d: %s\e[m\e[u" "$((stage + 1))" "$STAGE" "$(< "$TMP/stages/$stage/module")"
    btrfs subvolume snapshot "$TMP/root/imgs/$HASH" "$TMP/root/build"
    mount --bind "$TMP/root/build" "$TMP/root/build"
    mount --bind "$TMP/root/pkgs" "$TMP/root/build/var/cache/pacman/pkg"
    mount --mkdir --bind "$TMP/stages/$stage" "$TMP/root/build/stage"

    arch-chroot "$TMP/root/build" env -i SHELL=/bin/bash SYSTEMD_IN_CHROOT=1 bash -eu /stage/build.sh
    unmount "$TMP/root/build"
    rmdir "$TMP/root/build/stage"

    if [[ -d $TMP/root/imgs/$hash ]]; then btrfs subvolume delete --recursive "$TMP/root/imgs/$hash"; fi
    mv "$TMP/root/build" "$TMP/root/imgs/$hash"
  fi

  HASH="$hash"
  USED+=("$HASH")
done

if [[ ${SM_DRY:+x} ]]; then
  btrfs subvolume snapshot "$TMP/root/imgs/$HASH" "$TMP/root/build"
  mount --bind "$TMP/root/build" "$TMP/root/build"
  arch-chroot "$TMP/root/build" || true

  unmount "$TMP/root/build"
  btrfs subvolume delete --recursive "$TMP/root/build"
  exit
fi

printf "\e[s\e[H\e[K\e[1mDone!\e[m\e[u"
rm -f "$TMP/root/base"
ln -s "imgs/$HASH" "$TMP/root/base"

mount --mkdir --label BOOT "$TMP/boot"
find "$TMP/boot" -mindepth 1 -delete
cp -r "$TMP/root/base/boot/." "$TMP/boot"

for path in "$TMP/root/base/keep"/*; do
  target="$TMP/root/keep/${path##*/}"
  if [[ ! -e $target ]]; then cp -a "$path" "$target"; fi
done

for path in "$TMP/root/imgs"/*; do
  if [[ "${USED[*]}" != *${path##*/}* ]]; then
    btrfs subvolume delete --recursive "$path"
  fi
done

for path in "$TMP/root/keep"/*; do
  if [[ ! -e $TMP/root/base/keep/${path##*/} ]]; then
    read -rp "Remove '/keep/${path##*/}'? [y/N] "
    if [[ $REPLY == y ]]; then rm -rf "$path"; fi
  fi
done
