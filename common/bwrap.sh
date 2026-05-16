# bwrap <binary>
bwrap() {
  local binary="$1" target=".local/bin/${1##*/}"
  write -ux "$target" "#!/bin/sh"
  write -au "$target" "exec /usr/local/libexec/bwrap ${binary@Q} \"\$@\""
}

package bubblewrap
copy -x res/bin/bwrap.sh /usr/local/libexec/bwrap
symlink -u res/bin/bwrap.sh .local/bin/bw
