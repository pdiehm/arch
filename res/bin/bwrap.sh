#!/usr/bin/env bash

if (($# == 0)); then
  set /usr/bin/bash
fi

FLAGS=("--new-session" "--die-with-parent" "--unshare-all" "--share-net")
FLAGS+=("--dev" "/dev" "--proc" "/proc" "--tmpfs" "/tmp" "--bind" "$PWD" "$PWD")

for path in "/bin" "/etc" "/lib" "/lib64" "/sbin" "/usr" "/var"; do
  FLAGS+=("--ro-bind" "$path" "$path")
done

for path in ".ssh" ".local" ".cache" ".config/mozilla/firefox"; do
  FLAGS+=("--tmpfs" "$HOME/$path")
done

for path in "$(realpath /etc/resolv.conf)" "$XDG_RUNTIME_DIR/wayland-1" "/tmp/.X11-unix"; do
  FLAGS+=("--ro-bind-try" "$path" "$path")
done

exec bwrap "${FLAGS[@]}" "$@"
