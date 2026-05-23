package xdg-utils archlinux-xdg-menu
symlink -u res/mimeapps.list .config/mimeapps.list
copy -u res/user-places.xml .local/share/user-places.xbel

package dolphin gwenview ffmpegthumbs kdegraphics-thumbnailers
copy -u res/dolphin.toml .config/dolphinrc
copy -u res/gwenview.toml .config/gwenviewrc

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package mpv mpv-mpris
