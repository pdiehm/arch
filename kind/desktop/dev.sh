symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/arch/key .ssh/arch
copy -nsu ssh/github/key .ssh/github

package git-delta
symlink -u res/git.conf .config/git/config

persist -u -m 700 .local/share/gnupg
write -a /etc/gnupg/gpg-agent.conf "pinentry-program /usr/bin/pinentry-tty"

script -u << EOF
gpg --import "$(use res/key.gpg)"
gpg --quick-set-ownertrust 32104A99C1849AF79B2C92FCE85EB0566C779A2F ultimate
EOF

write -au .config/dropin/env << "EOF"
GNUPGHOME="$HOME/.local/share/gnupg"
GPG_TTY="$(tty)"
EOF
