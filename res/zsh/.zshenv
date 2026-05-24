# shellcheck disable=SC1090

export PATH="$HOME/.local/bin:$PATH"
export EZA_COLORS="xa=2;34"
export MANPAGER="bat --plain --language man --paging always --strip-ansi auto"

set -a
if [[ -f /etc/environment ]]; then source /etc/environment; fi
if [[ -f ~/.config/dropin/env.sh ]]; then source ~/.config/dropin/env.sh; fi
set +a
