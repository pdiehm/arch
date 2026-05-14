symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/arch .ssh/arch
copy -nsu ssh/bowser .ssh/bowser
copy -nsu ssh/goomba .ssh/goomba
copy -nsu ssh/github .ssh/github

package sshfs
copy -u res/systemd/user/home-pascal-Shared.mount .config/systemd/user/home-pascal-Shared.mount
systemd -u home-pascal-Shared.mount

write -au .config/dropin/env.sh "SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\""
copy -u res/systemd/user/ssh-agent.conf .config/systemd/user/ssh-agent.service.d/override.conf
systemd -ut sockets.target /usr/lib/systemd/user/ssh-agent.socket
