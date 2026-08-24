copy -s "keys/$HOST_NAME" /usr/local/lib/syscfg/key
if secret -q keys/master; then copy -s keys/master /usr/local/lib/syscfg/master; fi

script << EOF
sha256sum /usr/local/lib/syscfg/key | head -c 32 > /etc/machine-id
echo >> /etc/machine-id
EOF

write -a /etc/environment << EOF
HOSTNAME="$HOST_NAME"
HOSTKIND="$HOST_KIND"
EOF
