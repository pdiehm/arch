write /etc/hostname "$HOST_NAME"
copy res/hosts/static /etc/hosts

package -c dynhostmgr
copy res/hosts/dynamic /etc/dynhosts
run systemctl enable dynhostmgr.service

copy res/nftables.conf /etc/nftables.conf
run systemctl enable nftables.service

copy res/systemd/resolved.conf /etc/systemd/resolved.conf
copy res/systemd/system/resolvconf.service /etc/systemd/system/resolvconf.service
run systemctl enable systemd-resolved.service resolvconf.service
