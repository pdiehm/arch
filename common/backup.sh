if ((DRY)); then
  BACKUP=()
elif ((${#BACKUP[@]})); then
  var HOST "$HOST_NAME"
  var TARGETS "${BACKUP[*]}"
  copy -ex res/bin/backup.sh /usr/local/lib/backup/backup.sh

  copy -s backup /usr/local/lib/backup/key
  timer -n backup "Sat 03:00" /usr/local/lib/backup/backup.sh
fi
