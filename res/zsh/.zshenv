# shellcheck disable=SC1090

export PATH="$HOME/.local/bin:$PATH"
export EZA_COLORS="xa=2;34"
export MANPAGER="bat --plain --language man --paging always --strip-ansi auto"

if [[ -f ~/.config/env.sh ]]; then
  set -a
  source ~/.config/env.sh
  set +a
fi
