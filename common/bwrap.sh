# bwrap <binary>
bwrap() {
  local binary="$1" target=".local/bin/${1##*/}"
  write -ux "$target" "#!/bin/sh"
  write -au "$target" "exec /usr/local/lib/bwrap/wrap ${binary@Q} \"\$@\""
}

package bubblewrap
copy -x res/bin/bwrap.sh /usr/local/lib/bwrap/wrap
symlink -u res/bin/bwrap.sh .local/bin/bw
