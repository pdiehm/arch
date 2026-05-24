persist -u Repos
symlink -u res/bin/repo.sh .local/bin/repo
timer -nu repo-fetch hourly "%h/.local/bin/repo" fetch

package android-file-transfer sshfs
symlink -u res/bin/mnt.sh .local/bin/mnt

symlink -u res/mk .local/share/mk
symlink -u res/bin/mk.sh .local/bin/mk
