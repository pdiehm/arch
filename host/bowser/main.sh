import ./network
import ./zfs

persist -u shared
BACKUP+=("/home/pascal/shared")

timer backup-gc monthly /usr/bin/find /home/pascal/archive/Backups -mindepth 1 -mtime +30 -delete
