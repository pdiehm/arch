symlink -u res/ssh/ssh_config .ssh/config
copy -su ssh/arch .ssh/arch
copy -su ssh/bowser .ssh/bowser
copy -su ssh/goomba .ssh/goomba
copy -su ssh/github .ssh/github

package sshfs
systemd -iu home-pascal-Shared.mount
systemd -eu home-pascal-Shared.mount

write -au .config/dropin/env.sh "SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\""
systemd -ou ssh-agent.service
systemd -eu /usr/lib/systemd/user/ssh-agent.service
