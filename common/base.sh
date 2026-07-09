copy -s "keys/$HOST_NAME" /var/local/syscfg/key
if secret -q keys/master; then copy -s keys/master /var/local/syscfg/master; fi

script << EOF
sha256sum /var/local/syscfg/key | head -c 32 > /etc/machine-id
echo >> /etc/machine-id
EOF

write -a /etc/environment << EOF
HOSTNAME="$HOST_NAME"
HOSTKIND="$HOST_KIND"
EOF
