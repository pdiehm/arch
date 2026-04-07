option cpu amd
package man-db man-pages zsh vim openssh

run chsh -s /usr/bin/zsh pascal
copy res/ssh/known_hosts /etc/ssh/ssh_known_hosts
write -a /etc/environment "EDITOR=vim"

persist -u -m 700 .local/share/gnupg
symlink -u res/git.conf .config/git/config
symlink -u res/ssh/ssh_config .ssh/config
symlink -u res/zshrc.zsh .zshrc
copy -nsu ssh/github/key .ssh/github

run systemctl enable systemd-networkd.service systemd-resolved.service
write /etc/systemd/network/wired.network << EOF
[Match]
Type=ether
Kind=!*

[Network]
DHCP=ipv4
EOF
