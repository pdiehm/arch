#!/usr/bin/env bash

build() {
  add_binary btrfs
  add_binary find
  add_runscript
}

help() {
  echo "This hook initializes the root subvolume."
}
