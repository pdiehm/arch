symlink -u res/ssh/ssh_config .ssh/config
copy -su ssh/pascal-pc .ssh/pascal-pc
copy -su ssh/pascal-laptop .ssh/pascal-laptop
copy -su ssh/bowser .ssh/bowser
copy -su ssh/goomba .ssh/goomba
copy -su ssh/github .ssh/github
copy -su ssh/uni-gitlab .ssh/uni-gitlab

package sshfs
systemd -iu home-pascal-Shared.mount
systemd -eu home-pascal-Shared.mount

dropin env.sh "SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\""
systemd -ou ssh-agent.service
systemd -eu /usr/lib/systemd/user/ssh-agent.service
