symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/arch .ssh/arch
copy -nsu ssh/bowser .ssh/bowser
copy -nsu ssh/goomba .ssh/goomba
copy -nsu ssh/github .ssh/github

package sshfs
systemd -iu home-pascal-Shared.mount
systemd -eu home-pascal-Shared.mount

write -au .config/dropin/env.sh "SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\""
systemd -ou ssh-agent.service
systemd -eu /usr/lib/systemd/user/ssh-agent.service
