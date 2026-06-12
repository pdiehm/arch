# bwrap [-h dir] <binary>
#   -h   bind home directory
bwrap() {
  local OPTIND OPTARG opt
  local binds=()

  while getopts "h:" opt; do
    case "$opt" in
      h) binds+=("/home/pascal/$OPTARG") ;;
      *) error "Illegal option" ;;
    esac
  done

  shift $((OPTIND - 1))
  local binary="$1" target=".local/bin/${1##*/}" args=()
  write -ux "$target" "#!/bin/sh"

  for opt in "${binds[@]}"; do
    write -au "$target" "mkdir -p ${opt@Q}"
    args+=("--bind" "$opt" "$opt")
  done

  args+=("$binary")
  write -au "$target" "exec ~/.local/bin/bw ${args[*]@Q} \"\$@\""
}

package bubblewrap
symlink -u res/bin/bwrap.sh .local/bin/bw
