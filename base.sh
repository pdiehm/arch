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

# write [-aeux] [-m mode] <path> [content ...]
#   -a   append
#   -e   substitute environment variables
#   -u   as user in home directory
#   -x   set executable
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

  if (($# == 1)); then content="$(use)"; else content="$(use <<< "${*:2}")"; fi
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
#   -s   interpret src as secret name
#   -u   as user to home directory
#   -x   set executable
#   -m   set mode
copy() {
  local OPTIND OPTARG opt
  local envsubst=0 secret=0 user=0 executable=0 mode=""

  while getopts "esuxm:" opt; do
    case "$opt" in
      e) envsubst=1 ;;
      s) secret=1 ;;
      u) user=1 ;;
      x) executable=1 ;;
      m) mode="$OPTARG" ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  if ((secret)); then mode="${mode:-400}"; fi

  local src="$1" dst="$2" dir
  if ((secret)); then src="$(secret -f "$src")"; else src="$(use "$src")"; fi
  dir="$(dirname "$dst")"

  local cmd="mkdir -p ${dir@Q} && "
  if ((envsubst)); then cmd+="envsubst < ${src@Q} > ${dst@Q}"; else cmd+="cp -r ${src@Q} ${dst@Q}"; fi

  if [[ -n $mode ]]; then cmd+=" && chmod ${mode@Q} ${dst@Q}"; fi
  if ((executable)); then cmd+=" && chmod +x ${dst@Q}"; fi

  if ((user)); then
    run sudo -u pascal env -C /home/pascal bash -c "$cmd"
  else
    run bash -c "$cmd"
  fi
}

# symlink [-u] <target> <link>
#   -u   as user in home directory
symlink() {
  local OPTIND opt
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

  local cmd="if [[ -e ${link@Q} ]]; then echo 'Cannot create symlink' ${link@Q} '- File exists' >&2; exit 1; fi && "
  cmd+="mkdir -p ${dir@Q} && ln -s ${target@Q} ${link@Q}"

  if ((user)); then
    run sudo -u pascal env -C /home/pascal bash -c "$cmd"
  else
    run bash -c "$cmd"
  fi
}

# persist [-fu] [-m mode] <path>
#   -f   initialize as file
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
  if [[ $target == +* ]]; then target="/perm/${target:1}"; else target="/perm/home+pascal+$target"; fi

  local cmd="if [[ -e ${target@Q} ]]; then echo 'Cannot persist' ${path@Q} '- Already persisted' >&2; exit 1; fi && "
  cmd+="mkdir -p ${dir@Q} && if [[ -e ${path@Q} ]]; then mv ${path@Q} ${target@Q}; fi && ln -s ${target@Q} ${path@Q}"

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

# package <name> ...
package() {
  run pacman --noconfirm --sync --refresh --sysupgrade "$@"
}

# upgrade [command ...]
upgrade() {
  if (($#)); then
    write -a /var/local/syscfg/upgrade.sh "${*@Q}"
  else
    write -a /var/local/syscfg/upgrade.sh
  fi
}

# dropin <file> [text ...]
dropin() {
  local file="$1"

  if (($# == 1)); then
    write -au ".config/dropin/$file"
  else
    write -au ".config/dropin/$file" "${*:2}"
  fi
}

# systemd [-eu] [-t target] <unit> ...
#   -e   enable units
#   -u   in user manager
#   -t   for specific target
#
# systemd [-iu] <unit> ...
#   -i   install units
#   -u   in user manager
#
# systemd [-mu] <unit> ...
#   -m   mask units
#   -u   in user manager
#
# systemd [-ou] <unit> ...
#   -o   override units
#   -u   in user manager
systemd() {
  local OPTIND OPTARG opt
  local enable=0 install=0 mask=0 override=0 user=0 target=""

  while getopts "eimout:" opt; do
    case "$opt" in
      e) enable=1 ;;
      i) install=1 ;;
      m) mask=1 ;;
      o) override=1 ;;
      u) user=1 ;;
      t) target="$OPTARG" ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  if ((enable + install + mask + override > 1)); then error "Options '-e', '-i', '-m' and '-o' are mutually exclusive"; fi

  if ((enable)); then
    if [[ -n $target ]] && ((!user)); then error "Option '-t' requires '-u'"; fi

    if ((user)); then
      local unit target="${target:-default.target}"

      for unit; do
        if [[ $unit == /* ]]; then
          symlink -u "$unit" ".config/systemd/user/$target.wants/${unit##*/}"
        else
          symlink -u "/home/pascal/.config/systemd/user/$unit" ".config/systemd/user/$target.wants/$unit"
        fi
      done
    else
      run systemctl enable "$@"
    fi
  elif ((install)); then
    if [[ -n $target ]]; then error "Option '-t' cannot be used with '-i'"; fi

    if ((user)); then
      local unit
      for unit; do copy -u "res/systemd/user/$unit" ".config/systemd/user/$unit"; done
    else
      local unit
      for unit; do copy "res/systemd/system/$unit" "/etc/systemd/system/$unit"; done
    fi
  elif ((mask)); then
    if [[ -n $target ]]; then error "Option '-t' cannot be used with '-m'"; fi

    if ((user)); then
      local unit
      for unit; do symlink -u /dev/null ".config/systemd/user/$unit"; done
    else
      run systemctl mask "$@"
    fi
  elif ((override)); then
    if [[ -n $target ]]; then error "Option '-t' cannot be used with '-o'"; fi

    if ((user)); then
      local unit
      for unit; do copy -u "res/systemd/user/$unit" ".config/systemd/user/$unit.d/override.conf"; done
    else
      local unit
      for unit; do copy "res/systemd/system/$unit" "/etc/systemd/system/$unit.d/override.conf"; done
    fi
  else
    error "One of '-e', '-i', '-m' or '-o' is required"
  fi
}

# timer [-nu] <name> <time> <command> ...
#   -n   wait for network
#   -u   for user manager
timer() {
  local OPTIND opt
  local network=0 user=0

  while getopts "nu" opt; do
    case "$opt" in
      n) network=1 ;;
      u) user=1 ;;
      *) error "Invalid option: -$opt" ;;
    esac
  done

  shift $((OPTIND - 1))
  local name="$1" time="$2" command="$3" args=("${@:4}")

  local lf=$'\n'
  local timer="[Timer]${lf}Persistent=true${lf}OnCalendar=$time${lf}${lf}[Install]${lf}WantedBy=timers.target"

  local service="[Service]${lf}Type=oneshot"
  if ((network)); then service+="${lf}ExecStartPre=/bin/sh -c 'until ping -c 1 1.1.1.1; do sleep 1; done'"; fi
  service+="${lf}ExecStart=$command ${args[*]@Q}"

  if ((user)); then
    write -u ".config/systemd/user/$name.service" "$service"
    write -u ".config/systemd/user/$name.timer" "$timer"
    systemd -eut timers.target "$name.timer"
  else
    write "/etc/systemd/system/$name.service" "$service"
    write "/etc/systemd/system/$name.timer" "$timer"
    systemd -e "$name.timer"
  fi
}

persist /var/lib/systemd
copy -s "keys/$HOST_NAME" /var/local/syscfg/key
if secret -q keys/master; then copy -s keys/master /var/local/syscfg/master; fi

script << EOF
sha256sum /var/local/syscfg/key | head -c 32 > /etc/machine-id
echo >> /etc/machine-id
EOF

write -a /etc/pacman.conf << EOF
[aur]
SigLevel = Never
Server = https://pdiehm.github.io/aur
EOF

conf -e /etc/pacman.conf Color
package linux linux-firmware arch-install-scripts btrfs-progs cryptsetup sudo git
run pacman --files --refresh

upgrade pacman --noconfirm --sync --refresh --sysupgrade
upgrade pacman --files --refresh
timer pacman-gc monthly /usr/bin/pacman --noconfirm --sync --clean

run useradd --create-home --groups wheel --skel /var/empty --password "$(secret password)" --uid 1000 pascal
write -a /etc/sudoers "pascal ALL=(ALL:ALL) ALL"

script -u << EOF
git clone --recurse-submodules https://github.com/pdiehm/arch.git .config/syscfg
git --git-dir .config/syscfg/.git remote set-url origin git@github.com:pdiehm/arch.git
EOF

persist -u .config/syscfg
persist -u .local/share/systemd
symlink -u bin/manager.sh .local/bin/sm
