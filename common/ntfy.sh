copy -sm 444 ntfy /usr/local/lib/ntfy/token
copy -x res/bin/ntfy.sh /usr/local/bin/ntfy
symlink -u res/bin/ntfy.sh .local/bin/ntfy

copy -x res/bin/journalwatch.sh /usr/local/lib/journalwatch
systemd -i journalwatch.service
systemd -e journalwatch.service
