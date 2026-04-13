symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/github/key .ssh/github

persist -u -m 700 .local/share/gnupg
run ln -sf /usr/bin/pinentry-tty /usr/bin/pinentry

symlink -u res/git.conf .config/git/config

write -au .config/dropin/env << "EOF"
export GNUPGHOME="$HOME/.local/share/gnupg"
export GPG_TTY="$(tty)"
EOF
