#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob dotglob globstar
trap "rm -f /var/tmp/backup.sh" EXIT

if [[ -x /usr/local/lib/backup/pre.sh ]]; then
  bash -e /usr/local/lib/backup/pre.sh
fi

# shellcheck disable=SC2086
tar czf /var/tmp/backup.tgz $TARGETS

if [[ -x /usr/local/lib/backup/post.sh ]]; then
  bash -e /usr/local/lib/backup/post.sh
fi

scp -i /usr/local/lib/backup/key -P 1970 /var/tmp/backup.tgz "pascal@bowser:/home/pascal/archive/Backups/${HOST}_$(date -I).tgz"
