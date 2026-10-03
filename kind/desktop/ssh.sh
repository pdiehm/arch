symlink -u res/ssh/ssh_config .ssh/config
copy -su ssh/pascal-pc .local/keys/ssh/pascal-pc
copy -su ssh/pascal-laptop .local/keys/ssh/pascal-laptop
copy -su ssh/bowser .local/keys/ssh/bowser
copy -su ssh/goomba .local/keys/ssh/goomba
copy -su ssh/github .local/keys/ssh/github
copy -su ssh/uni-gitlab .local/keys/ssh/uni-gitlab
copy -su ssh/iso .local/keys/ssh/iso
guard -b /usr/bin/ssh -b /usr/bin/ssh-add -u .local/keys/ssh

systemd -eu /usr/lib/systemd/user/ssh-agent.service
write -au .config/dropin/env.sh 'SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"'

write -u .config/systemd/user/ssh-agent.service.d/keys.conf << EOF
[Service]
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStartPost=/usr/local/bin/ssh-add "%h/.local/keys/ssh/github"
EOF

package sshfs
systemd -ieu home-pascal-Shared.mount
