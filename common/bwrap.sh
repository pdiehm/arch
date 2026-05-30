# bwrap <binary>
bwrap() {
  local binary="$1" target=".local/bin/${1##*/}"
  write -ux "$target" "#!/bin/sh"
  write -au "$target" "exec ~/.local/bin/bw ${binary@Q} \"\$@\""
}

package bubblewrap
symlink -u res/bin/bwrap.sh .local/bin/bw
