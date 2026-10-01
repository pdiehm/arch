symlink -u res/ssh/ssh_config .ssh/config
copy -su ssh/pascal-pc .ssh/pascal-pc
copy -su ssh/pascal-laptop .ssh/pascal-laptop
copy -su ssh/bowser .ssh/bowser
copy -su ssh/goomba .ssh/goomba
copy -su ssh/github .ssh/github
copy -su ssh/uni-gitlab .ssh/uni-gitlab
copy -su ssh/iso .ssh/iso

systemd -eu /usr/lib/systemd/user/ssh-agent.service
write -au .config/dropin/env.sh 'SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"'

write -u .config/systemd/user/ssh-agent.service.d/keys.conf << EOF
[Service]
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStartPost=/usr/bin/ssh-add "%h/.ssh/github"
EOF

package sshfs
systemd -ieu home-pascal-Shared.mount
