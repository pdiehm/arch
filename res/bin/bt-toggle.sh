#!/usr/bin/env bash

COMMAND="$1"

if [[ $COMMAND == power ]]; then
  if [[ $(bluetoothctl show | sed -n "s/^\s*Powered: //p") == no ]]; then
    bluetoothctl power on
  else
    bluetoothctl power off
  fi
elif [[ $COMMAND == discoverable ]]; then
  if [[ $(bluetoothctl show | sed -n "s/^\s*Discoverable: //p") == no ]]; then
    bluetoothctl discoverable on
  else
    bluetoothctl discoverable off
  fi
else
  echo "Usage: bt-toggle (power|discoverable)"
  exit 1
fi
