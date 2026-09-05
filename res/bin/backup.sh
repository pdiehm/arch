#!/usr/bin/env bash

shopt -s nullglob dotglob globstar
CODE=0

if [[ -x /usr/local/lib/backup/pre.sh ]]; then
  bash -e /usr/local/lib/backup/pre.sh || CODE="$((CODE | 1))"
fi

tar czf /var/tmp/backup.tgz @TARGETS@ || CODE="$((CODE | 2))"

if [[ -x /usr/local/lib/backup/post.sh ]]; then
  bash -e /usr/local/lib/backup/post.sh || CODE="$((CODE | 4))"
fi

scp -i /usr/local/lib/backup/key -P 1970 /var/tmp/backup.tgz "pascal@bowser:/home/pascal/archive/Backups/@HOST@_$(date -I).tgz" || CODE="$((CODE | 8))"
rm -f /var/tmp/backup.tgz
exit "$CODE"
