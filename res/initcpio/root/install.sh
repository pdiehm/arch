#!/usr/bin/env bash

build() {
  add_all_modules /crypto/
  map add_module dm-crypt dm-integrity "hid-generic?"
  map add_udev_rule 10-dm.rules 13-dm-disk.rules 95-dm-notify.rules
  map add_binary cryptsetup /usr/lib/libgcc_s.so.1 /usr/lib/ossl-modules/legacy.so

  map add_binary btrfs find shred
  add_module vfat
  add_runscript
}

help() {
  echo "This hook decrypts the root device and initializes a new subvolume."
}
