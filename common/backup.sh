if ((DRY)); then
  BACKUP=()
elif ((${#BACKUP[@]})); then
  copy -s ssh/backup /usr/local/lib/backup/key
  timer -n backup "Sat 03:00" /usr/local/lib/backup/backup.sh

  write -x /usr/local/lib/backup/backup.sh << EOF
#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob dotglob globstar
trap "rm -f /var/tmp/backup.tgz" EXIT

tar czf /var/tmp/backup.tgz ${BACKUP[*]}
scp -i /usr/local/lib/backup/key -P 1970 /var/tmp/backup.tgz pascal@bowser:/home/pascal/archive/Backups/${HOST_NAME}_\$(date -I).tgz
EOF
fi
