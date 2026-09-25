persist -u Repos
symlink -u res/bin/repo.sh .local/bin/repo
timer -nu repo-fetch hourly "%h/.local/bin/repo" fetch

package grim slurp swappy hyprpicker
symlink -u res/swappy.conf .config/swappy/config
symlink -u res/bin/hyprshot.sh .local/bin/hyprshot

package android-file-transfer sshfs
symlink -u res/bin/mnt.sh .local/bin/mnt

symlink -u res/mk .local/share/mk
symlink -u res/bin/mk.sh .local/bin/mk

package bubblewrap
symlink -u res/bin/bwrap.sh .local/bin/bw

symlink -u res/bin/bt-toggle.sh .local/bin/bt-toggle
symlink -u res/bin/genpw.sh .local/bin/genpw
symlink -u res/bin/wp-toggle.sh .local/bin/wp-toggle
