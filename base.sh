# script [-u] [path [args ...]]
#   -u   as user in home directory
script() {
  local OPTIND opt
  local user=0

  while getopts "u" opt; do
    case "$opt" in
      u) user=1 ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  local path="${1:--}" args=("${@:2}")
  path="$(use "$path")"

  if ((user)); then
    run sudo -u pascal env -C /home/pascal bash -eu "$path" "${args[@]}"
  else
    run bash -eu "$path" "${args[@]}"
  fi
}

# write [-aeux] [-m mode] <path> [content]
#   -a   append
#   -e   substitute environment variables
#   -u   as user in home directory
#   -x   executable
#   -m   set mode
write() {
  local OPTIND OPTARG opt
  local append=0 envsubst=0 user=0 executable=0 mode=""

  while getopts "aeuxm:" opt; do
    case "$opt" in
      a) append=1 ;;
      e) envsubst=1 ;;
      u) user=1 ;;
      x) executable=1 ;;
      m) mode="$OPTARG" ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  local path="$1" content dir

  if (($# == 1)); then content="$(use)"; else content="$(use <<< "$2")"; fi
  dir="$(dirname "$path")"

  local cmd="mkdir -p ${dir@Q} && "
  if ((envsubst)); then cmd+="envsubst < ${content@Q} "; else cmd+="cat ${content@Q} "; fi
  if ((append)); then cmd+=">> ${path@Q}"; else cmd+="> ${path@Q}"; fi

  if [[ -n $mode ]]; then cmd+=" && chmod ${mode@Q} ${path@Q}"; fi
  if ((executable)); then cmd+=" && chmod +x ${path@Q}"; fi

  if ((user)); then
    run sudo -u pascal env -C /home/pascal bash -c "$cmd"
  else
    run bash -c "$cmd"
  fi
}

# copy [-ensux] [-m mode] <src> <dst>
#   -e   substitute environment variables
#   -n   insert final newline
#   -s   interpret src as secret name
#   -u   as user to home directory
#   -x   executable
#   -m   set mode
copy() {
  local OPTIND OPTARG opt
  local envsubst=0 newline=0 secret=0 user=0 executable=0 mode=""

  while getopts "ensuxm:" opt; do
    case "$opt" in
      e) envsubst=1 ;;
      n) newline=1 ;;
      s) secret=1 ;;
      u) user=1 ;;
      x) executable=1 ;;
      m) mode="$OPTARG" ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  if ((secret)) && [[ -z $mode ]]; then mode="400"; fi

  local src="$1" dst="$2" dir
  if ((secret)); then src="$(secret -f "$src")"; else src="$(use "$src")"; fi
  dir="$(dirname "$dst")"

  local cmd="mkdir -p ${dir@Q} && "
  if ((envsubst)); then cmd+="envsubst < ${src@Q} > ${dst@Q}"; else cmd+="cp -r ${src@Q} ${dst@Q}"; fi

  if [[ -n $mode ]]; then cmd+=" && chmod ${mode@Q} ${dst@Q}"; fi
  if ((executable)); then cmd+=" && chmod +x ${dst@Q}"; fi

  if ((user)); then
    run sudo -u pascal env -C /home/pascal bash -c "$cmd"
    if ((newline)); then run env -C /home/pascal bash -c "printf '\n' >> ${dst@Q}"; fi
  else
    run bash -c "$cmd"
    if ((newline)); then run bash -c "printf '\n' >> ${dst@Q}"; fi
  fi
}

# symlink [-u] <target> <link>
#   -u   as user in home directory
symlink() {
  local OPTIND OPTARG opt
  local user=0

  while getopts "u" opt; do
    case "$opt" in
      u) user=1 ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  local target="$1" link="$2" dir
  dir="$(dirname "$link")"

  if [[ $target != /* ]]; then
    target="$(realpath -e "$(resolve "$target")")"
    target="${target/#$PWD//home/pascal/.config/syscfg}"
  fi

  local cmd="if [[ -e ${link@Q} ]]; then echo 'Cannot create symlink' ${link@Q} '- File exists' >&2; exit 1; fi"
  cmd+=" && mkdir -p ${dir@Q} && ln -s ${target@Q} ${link@Q}"

  if ((user)); then
    run sudo -u pascal env -C /home/pascal bash -c "$cmd"
  else
    run bash -c "$cmd"
  fi
}

# persist [-fu] [-m mode] <path>
#   -f   create file if it does not exist
#   -u   as user in home directory
#   -m   set mode if created
persist() {
  local OPTIND OPTARG opt
  local file=0 user=0 mode=""

  while getopts "fum:" opt; do
    case "$opt" in
      f) file=1 ;;
      u) user=1 ;;
      m) mode="$OPTARG" ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  local path="$1" dir target
  dir="$(dirname "$path")"

  target="${path//+/_}"
  target="${target//\//+}"
  target="${target//[^a-zA-Z0-9._+-]/_}"
  if [[ $target == +* ]]; then target="/perm/ROOT$target"; else target="/perm/HOME+$target"; fi

  local cmd="if [[ -e ${target@Q} ]]; then echo 'Cannot persist' ${path@Q} '- Already persisted' >&2; exit 1; fi"
  cmd+=" && mkdir -p ${dir@Q} && if [[ -e ${path@Q} ]]; then mv ${path@Q} ${target@Q}; fi && ln -s ${target@Q} ${path@Q}"

  cmd+=" && if [[ ! -e ${target@Q} ]]; then "
  if ((file)); then cmd+="touch ${target@Q}; "; else cmd+="mkdir ${target@Q}; "; fi
  if [[ -n $mode ]]; then cmd+="chmod ${mode@Q} ${target@Q}; "; fi
  cmd+="fi"

  if ((user)); then
    run sudo -u pascal env -C /home/pascal bash -c "$cmd"
  else
    run bash -c "$cmd"
  fi
}

# env <name> <value>
env() {
  local name="$1" value="$2"
  run export "$name=$value"
}

# conf [-de] <path> <name> ...
#   -d   disable
#   -e   enable
conf() {
  local OPTIND opt
  local disable=0 enable=0

  while getopts "de" opt; do
    case "$opt" in
      d) disable=1 ;;
      e) enable=1 ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  if ((disable + enable > 1)); then error "Options '-d' and '-e' are mutually exclusive"; fi

  local path="$1" names=("${@:2}") name
  for name in "${names[@]}"; do
    if ((disable)); then
      run sed -Ei "s|^#?($name)\b|#\1|" "$path"
    elif ((enable)); then
      run sed -Ei "s|^#?($name)\b|\1|" "$path"
    else
      run sed -Ei "s|^#?${name%%=*}\b.*$|$name|" "$path"
    fi
  done
}

# package [-ac] <name> ...
#   -a   from AUR
#   -c   custom package
package() {
  local OPTIND opt
  local aur=0 custom=0

  while getopts "ac" opt; do
    case "$opt" in
      a) aur=1 ;;
      c) custom=1 ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  if ((aur + custom > 1)); then error "Options '-a' and '-c' are mutually exclusive"; fi

  if ((aur)); then
    run paru --noconfirm --sync --sysupgrade --refresh --needed "$@"
  elif ((custom)); then
    local name
    for name; do
      copy "pkgs/$name" "/var/lib/syscfg/pkgs/$name"
      run chown -R pkgbuild:pkgbuild "/var/lib/syscfg/pkgs/$name"

      local cmd=(sudo -u pkgbuild env -C "/var/lib/syscfg/pkgs/$name" makepkg --clean --install --rmdeps --syncdeps --noconfirm)
      run "${cmd[@]}"
      upgrade "${cmd[@]}"
    done
  else
    run pacman --noconfirm --sync --sysupgrade --refresh --needed "$@"
  fi
}

# upgrade [command ...]
upgrade() {
  if (($# == 0)); then
    write -a /var/lib/syscfg/upgrade.sh
  else
    write -a /var/lib/syscfg/upgrade.sh "${*@Q}"
  fi
}

copy -s "keys/$HOST_NAME" /var/lib/syscfg/key
if secret -q keys/master; then copy -s keys/master /var/lib/syscfg/master; fi

persist -f /etc/machine-id
persist /var/lib/systemd

conf -e /etc/pacman.conf Color
package base-devel linux linux-firmware arch-install-scripts btrfs-progs git

run useradd --create-home --system --home-dir /var/lib/syscfg/pkgs --skel /var/empty --shell /usr/bin/nologin pkgbuild
write -a /etc/sudoers "pkgbuild ALL=(ALL:ALL) NOPASSWD: ALL"

package -c paru
conf -e /etc/paru.conf BottomUp CleanAfter RemoveMake SudoLoop
upgrade paru --noconfirm --newsonupgrade --sync --sysupgrade --refresh

run useradd --create-home --groups wheel --skel /var/empty --password "$(secret password)" --uid 1000 pascal
write -a /etc/sudoers "pascal ALL=(ALL:ALL) ALL"

script -u << EOF
git clone --recurse-submodules https://github.com/pdiehm/arch.git .config/syscfg
git --git-dir .config/syscfg/.git remote set-url origin git@github.com:pdiehm/arch.git
EOF

persist -u .config/syscfg
symlink -u bin/manager.sh .local/bin/sm
