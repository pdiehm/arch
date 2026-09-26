import ./network
import ./zfs

persist -u shared
BACKUP+=("/home/pascal/shared")

timer -u backup-gc monthly /usr/bin/find archive/Backups -mtime +30 -delete
