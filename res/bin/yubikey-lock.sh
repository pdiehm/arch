#!/usr/bin/env bash

shopt -s nullglob

for device in /dev/input/event*; do
  if ! evtest --query "$device" EV_KEY KEY_LEFTCTRL; then
    for led in /sys/class/leds/*::capslock/brightness; do echo 1 > "$led"; done
    exit
  fi
done

loginctl lock-sessions
