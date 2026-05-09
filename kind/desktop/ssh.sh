symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/arch .ssh/arch
copy -nsu ssh/bowser .ssh/bowser
copy -nsu ssh/goomba .ssh/goomba
copy -nsu ssh/github .ssh/github

package sshfs
symlink -u res/systemd/user/home-pascal-Shared.mount .config/systemd/user/home-pascal-Shared.mount
symlink -u /home/pascal/.config/systemd/user/home-pascal-Shared.mount .config/systemd/user/default.target.wants/home-pascal-Shared.mount
