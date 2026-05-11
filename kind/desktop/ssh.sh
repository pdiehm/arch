symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/arch .ssh/arch
copy -nsu ssh/bowser .ssh/bowser
copy -nsu ssh/goomba .ssh/goomba
copy -nsu ssh/github .ssh/github

package sshfs
write -au .config/dropin/env "SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\""
