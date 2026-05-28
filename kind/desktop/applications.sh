package xdg-utils archlinux-xdg-menu
symlink -u res/mimeapps.list .config/mimeapps.list
copy -um 444 res/user-places.xml .local/share/user-places.xbel

package dolphin gwenview ffmpegthumbs kdegraphics-thumbnailers
copy -um 444 res/dolphin.toml .config/dolphinrc
copy -um 444 res/gwenview.toml .config/gwenviewrc

package firefox
persist -u .config/mozilla/firefox
symlink res/firefox.json /etc/firefox/policies/policies.json

package inkscape gimp pdfpc mpv mpv-mpris tenacity
