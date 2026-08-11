import ./network
package tenacity kdenlive qemu-full quickemu

package cups ipp-usb
systemd -e cups.service ipp-usb.service

package via-bin
copy res/udev/via.rules /etc/udev/rules.d/10-via.rules

package retroarch retroarch-assets-ozone
persist -u .config/retroarch
BACKUP+=("/home/pascal/.config/retroarch/{retroarch.cfg,autoconfig,config,saves}")
