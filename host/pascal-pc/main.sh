import ./network

package cups ipp-usb
systemd -e cups.service ipp-usb.service

package via-bin
copy res/udev/via.rules /etc/udev/rules.d/10-via.rules

package retroarch retroarch-assets-ozone
persist -u .config/retroarch
BACKUP+=("/home/pascal/.config/retroarch/{retroarch.cfg,autoconfig,config,saves}")

package prismlauncher
persist -u .local/share/PrismLauncher
BACKUP+=("/home/pascal/.local/share/PrismLauncher/instances/*/minecraft/saves")

write /etc/systemd/system/alsa-restore.service.d/auto-mute.conf "[Service]" 'ExecStartPost=/usr/bin/amixer -c 2 sset "Auto-Mute Mode" Disabled'
package tenacity kdenlive k3b qemu-full quickemu
