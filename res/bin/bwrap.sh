#!/usr/bin/env bash

if (($# == 0)); then
  set /usr/bin/bash
fi

FLAGS=("--new-session" "--die-with-parent" "--unshare-all" "--share-net")
FLAGS+=("--dev" "/dev" "--proc" "/proc" "--bind" "/perm" "/perm" "--bind" "$PWD" "$PWD")

for path in "/bin" "/etc" "/lib" "/lib64" "/sbin" "/usr" "/var" "$(realpath /etc/resolv.conf)"; do
  FLAGS+=("--ro-bind" "$path" "$path")
done

for path in "/perm/home+pascal+.config+mozilla+firefox" "/perm/home+pascal+.local+share+gnupg"; do
  FLAGS+=("--ro-bind" "/var/empty" "$path")
done

for path in "$HOME/.ssh" "$HOME/.local/keys" "$HOME/.cache/mozilla"; do
  FLAGS+=("--ro-bind" "/var/empty" "$path")
done

exec bwrap "${FLAGS[@]}" "$@"
