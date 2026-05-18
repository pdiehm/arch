package dolphin gwenview archlinux-xdg-menu ffmpegthumbs kdegraphics-thumbnailers
copy -u res/dolphin.toml .config/dolphinrc
copy -u res/gwenview.toml .config/gwenviewrc
copy -u res/user-places.xml .local/share/user-places.xbel

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package mpv mpv-mpris
