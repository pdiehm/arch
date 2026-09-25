#!/usr/bin/env bash

if [[ $1 == pixel ]]; then
  exec hyprpicker --autocopy
elif [[ $1 == region ]]; then
  grim -g "$(slurp)" - | swappy -f -
elif [[ $1 == window ]]; then
  REGION="$(hyprctl -j activewindow | jq --raw-output '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
  grim -g "$REGION" - | swappy -f -
elif [[ $1 == monitor ]]; then
  MONITOR="$(hyprctl -j activeworkspace | jq --raw-output .monitor)"
  grim -o "$MONITOR" - | swappy -f -
fi
