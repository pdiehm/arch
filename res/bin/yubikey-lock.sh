#!/usr/bin/env bash

for device in /dev/input/event*; do
  if ! evtest --query "$device" EV_KEY KEY_LEFTCTRL; then exit; fi
done

loginctl lock-sessions
