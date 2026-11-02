if ((DRY)); then
  BACKUP=()
elif ((${#BACKUP[@]})); then
  copy -x -v "HOST=$HOST_NAME" -v "TARGETS=${BACKUP[*]}" res/bin/backup.sh /usr/local/lib/backup/backup.sh
  copy -s ssh/backup /usr/local/keys/backup
  timer -nh bowser backup "Sat 03:00" /usr/local/lib/backup/backup.sh
fi
