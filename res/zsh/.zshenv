# shellcheck disable=SC1090

export PATH="$HOME/.local/bin:$PATH"
export EZA_COLORS="xa=2;34"

if [[ -f ~/.config/dropin/env ]]; then
  set -a
  source ~/.config/dropin/env
  set +a
fi
