package xdg-utils archlinux-xdg-menu adwaita-icon-theme
symlink -u res/mimeapps.list .config/mimeapps.list
copy -um 444 res/user-places.xml .local/share/user-places.xbel

package dolphin gwenview ffmpegthumbs kdegraphics-thumbnailers
copy -um 444 res/dolphin.toml .config/dolphinrc
copy -um 444 res/gwenview.toml .config/gwenviewrc

package firefox
guard -b /usr/bin/firefox _firefox 9999
persist -uo root:_firefox -m 770 .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package aerc w3m
symlink -u res/aerc .config/aerc
copy -su mail/gmail .local/keys/aerc/gmail
copy -su mail/uni .local/keys/aerc/uni
guard -b /usr/bin/aerc -u .local/keys/aerc
