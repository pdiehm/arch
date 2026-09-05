#!/usr/bin/env bash

SOURCE="$1"
TARGET="${2:-$SOURCE}"

if [[ ! $SOURCE ]]; then
  echo "Usage: mk <source> [target]"
  exit 1
elif [[ ! -f /home/pascal/.local/share/mk/$SOURCE ]]; then
  echo "Cannot make '$SOURCE'"
  exit 1
elif [[ -e $TARGET ]]; then
  echo "$TARGET already exists"
  exit 1
else
  sed "s/@YEAR@/$(date "+%Y")/g" "/home/pascal/.local/share/mk/$SOURCE" > "$TARGET"
fi
