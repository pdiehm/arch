#!/usr/bin/env bash

SCRIPT="s/^\w+ \w+ \S+ \S+ ([^:[]+)[^:]*: (.+)$/\1:::\2/;"
SCRIPT+="s/^systemd:::Startup finished in .+ = (.+)\.$/[systemd] Booted in \1/p;"
SCRIPT+="s/^systemd:::(\S+): Failed with result '(.+)'\.$/[systemd] \1 failed: \2/p;"
SCRIPT+="s/^sudo:::\s+(\S+) : .* USER=(\S+) .* COMMAND=(.+)$/[sudo] \1 as \2: \3/p;"
SCRIPT+="s/^sshd-session:::(Accepted|Failed) password for (\S+) from (\S+) port \w+ ssh2$/[ssh] \1 password for \2 from \3/p;"
SCRIPT+="s/^sshd-session:::(Accepted|Failed) publickey for (\S+) from (\S+) port \w+ ssh2: .*$/[ssh] \1 publickey for \2 from \3/p;"
SCRIPT+="s/^sshd-session:::Invalid user (\S+) from (\S+) port \w+$/[ssh] Invalid user \1 from \2/p;"
SCRIPT+="s/^sshd-session:::User (\S+) from (\S+) not allowed because not listed in AllowUsers$/[ssh] Denied user \1 from \2/p;"

journalctl --follow --no-tail | sed -Enu "$SCRIPT" | while read -r msg; do ntfy "$msg" || true; done
