package gnupg
write -a /etc/gnupg/gpg-agent.conf "pinentry-program /usr/bin/pinentry-tty"

write -au .config/dropin/env.sh << "EOF"
GNUPGHOME="$HOME/.local/share/gnupg"
GPG_TTY="$TTY"
EOF

script -u << EOF
export GNUPGHOME="/home/pascal/.local/share/gnupg"
mkdir -pm 700 "\$GNUPGHOME"
gpg --import "$(use res/key.gpg)"
gpg --quick-set-ownertrust 32104A99C1849AF79B2C92FCE85EB0566C779A2F ultimate
EOF

persist -u .local/share/gnupg
