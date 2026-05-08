export PATH="$HOME/.local/bin:$PATH"
export EZA_COLORS="xa=2;34"

if [[ -f ~/.config/dropin/env ]]; then
  # shellcheck disable=SC1090
  source ~/.config/dropin/env
fi
