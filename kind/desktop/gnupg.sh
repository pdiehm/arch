package gnupg
persist -um 700 .local/share/gnupg
write -a /etc/gnupg/gpg-agent.conf "pinentry-program /usr/bin/pinentry-tty"

script -u << EOF
export GNUPGHOME="/home/pascal/.local/share/gnupg"
gpg --import "$(use res/key.gpg)"
gpg --quick-set-ownertrust 32104A99C1849AF79B2C92FCE85EB0566C779A2F ultimate
EOF

dropin env.sh << "EOF"
GNUPGHOME="$HOME/.local/share/gnupg"
GPG_TTY="$TTY"
EOF
