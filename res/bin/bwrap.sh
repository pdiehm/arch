#!/usr/bin/env bash

if (($# == 0)); then
  set /usr/bin/bash
fi

exec bwrap --new-session --die-with-parent --unshare-all --share-net --dev /dev --proc /proc \
  --ro-bind /bin /bin --ro-bind /sbin /sbin --ro-bind /lib /lib --ro-bind /lib64 /lib64 \
  --ro-bind /etc /etc --ro-bind /usr /usr --ro-bind /var /var \
  --ro-bind-try "$(realpath /etc/resolv.conf)" "$(realpath /etc/resolv.conf)" \
  --bind "$PWD" "$PWD" "$@"
