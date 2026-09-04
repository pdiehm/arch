symlink -u res/ssh/ssh_config .ssh/config
copy -su ssh/keys/pascal-pc .ssh/pascal-pc
copy -su ssh/keys/pascal-laptop .ssh/pascal-laptop
copy -su ssh/keys/bowser .ssh/bowser
copy -su ssh/keys/goomba .ssh/goomba
copy -su ssh/keys/github .ssh/github
copy -su ssh/keys/uni-gitlab .ssh/uni-gitlab

systemd -eu /usr/lib/systemd/user/ssh-agent.service
write -au .config/dropin/env.sh 'SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"'

write -u .config/systemd/user/ssh-agent.service.d/keys.conf << EOF
[Service]
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStartPost=/usr/bin/ssh-add "%h/.ssh/github"
EOF

package sshfs
systemd -iu home-pascal-Shared.mount
systemd -eu home-pascal-Shared.mount
