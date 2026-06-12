#!/usr/bin/env bash

if (($# == 0)); then
  set /usr/bin/bash
fi

FLAGS=("--new-session" "--die-with-parent" "--unshare-all" "--share-net")
FLAGS+=("--dev" "/dev" "--proc" "/proc" "--bind" "/perm" "/perm" "--bind" "$PWD" "$PWD")

for path in "/bin" "/etc" "/lib" "/lib64" "/sbin" "/usr" "/var"; do
  FLAGS+=("--ro-bind" "$path" "$path")
done

for path in "/tmp" "/perm/home-pascal-.local-share-gnupg" "/perm/home-pascal-.config-mozilla-firefox" "$HOME/.ssh" "$HOME/.local" "$HOME/.cache"; do
  FLAGS+=("--tmpfs" "$path")
done

for path in "$(realpath /etc/resolv.conf)" "$XDG_RUNTIME_DIR/wayland-1" "/tmp/.X11-unix"; do
  FLAGS+=("--ro-bind" "$path" "$path")
done

exec bwrap "${FLAGS[@]}" "$@"
