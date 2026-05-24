# shellcheck disable=SC1094,SC2016,SC2034,SC2140,SC2154,SC2155,SC2164

setopt PROMPT_SUBST
PROMPT='%F{4}%~%f$(_prompt_git) %F{%(?.5.1)}$(_prompt_char)%f '
RPROMPT='$(_prompt_host)'

_prompt_git() {
  if ! git rev-parse HEAD &> /dev/null; then
    return
  fi

  local branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ $branch == HEAD ]]; then
    echo -n " %F{3}$(git rev-parse --short HEAD)%f"
  else
    echo -n " %F{8}$branch%f"
  fi

  local changes="$(git status --porcelain)"
  local staged="$(grep -Ec "^\w." <<< "$changes")"
  local changed="$(grep -Ec "^.(\w|\?)" <<< "$changes")"

  if ((changed && staged)); then
    echo -en "%F{6}\u203d%f"
  elif ((changed)); then
    echo -n "%F{6}?%f"
  elif ((staged)); then
    echo -n "%F{6}!%f"
  fi

  if [[ -n "$(git stash list)" ]]; then
    echo -en " %F{6}\u2026%f"
  fi

  if [[ -n "$(git remote show)" && $branch != HEAD ]]; then
    if git rev-parse "@{upstream}" &> /dev/null; then
      local ahead="$(git rev-list --count "@{upstream}..")"
      local behind="$(git rev-list --count "..@{upstream}")"

      if ((ahead && behind)); then
        echo -en " %F{6}\u296f%f"
      elif ((ahead)); then
        echo -en " %F{6}\u2191%f"
      elif ((behind)); then
        echo -en " %F{6}\u2193%f"
      fi
    else
      echo -en " %F{6}\u21a5%f"
    fi
  fi

  local git="$(git rev-parse --git-dir)"
  if [[ -f $git/BISECT_LOG ]]; then
    echo -n " %F{1}(bisect)%f"
  elif [[ -f $git/CHERRY_PICK_HEAD ]]; then
    echo -n " %F{1}(cherry-pick)%f"
  elif [[ -f $git/MERGE_HEAD ]]; then
    echo -n " %F{1}(merge)%f"
  elif [[ -f $git/REVERT_HEAD ]]; then
    echo -n " %F{1}(revert)%f"
  elif [[ -f $git/REBASE_HEAD ]]; then
    local step="$(< "$git/rebase-merge/msgnum")"
    local total="$(< "$git/rebase-merge/end")"
    echo -n " %F{1}(rebase)%f %F{6}$step%F{8}/%F{6}$total%f"
  fi
}

_prompt_char() {
  if [[ $TTY == /dev/tty* ]]; then
    echo -n ">"
  else
    echo -en "\u276f"
  fi
}

_prompt_host() {
  if [[ -n ${SSH_TTY:+x} ]]; then
    echo -n "%F{14}%n@%M%f"
  fi
}

alias dog="doggo"
alias fd="fd --follow --hidden"
alias l="ls --all --all --long --group"
alias ls="eza"
alias lsblk="lsblk --output NAME,TYPE,SIZE,VENDOR,MODEL,PTTYPE,PARTLABEL,PARTTYPENAME,LABEL,FSTYPE,MOUNTPOINTS"
alias parallel="parallel --group --keep-order"
alias rg="rg --follow --hidden --smart-case"
alias type="type -as"

if [[ $HOSTKIND == desktop ]]; then
  alias open="xdg-open"
  alias play="ffplay -autoexit -nodisp"
  alias py="python3"
fi

await() {
  local pre="$(date "+%s%3N")"
  eval "$*"

  local result="$?"
  local post="$(date "+%s%3N")"
  local time="$((post - pre))"

  if ((time < 1000)); then
    time="${time}ms"
  elif ((time < 60000)); then
    time="$((time / 1000))s"
  elif ((time < 3600000)); then
    time="$((time / 60000))m $((time / 1000 % 60))s"
  else
    time="$((time / 3600000))h $((time / 60000 % 60))m $((time / 1000 % 60))s"
  fi

  ntfy "Command '$*' finished in $time with exit code $result"
  return "$result"
}

ed() {
  if (($# == 0)); then
    "$EDITOR"
  elif [[ -d $1 ]]; then
    pushd "$1"
    "$EDITOR" .
    popd
  else
    local dir="$(dirname "$1")"
    mkdir -p "$dir"

    pushd "$dir"
    "$EDITOR" "$(basename "$1")"
    popd
  fi
}

mkcd() {
  mkdir -p "$1"
  cd "$1"
}

mktex() {
  latexmk -cd -pdf -outdir="$PWD/build" "$1"
}

watch() (
  trap "printf '\e[?25h\e[?1049l'" EXIT
  trap "exit 0" INT

  printf "\e[?25l\e[?1049h"
  while true; do
    echo -e "\e[H\e[2mWatching: $*\e[m\n"
    script --quiet --command "zsh --interactive -c $(printf "%q" "$*")" /dev/null | sed $'s/^/\e[K/'

    printf "\e[J"
    sleep 1
  done
)

bindkey -rp ""
bindkey -R " "-"~" self-insert
bindkey -R "\M-^@"-"\M-^?" self-insert

bindkey "^M" accept-line                         # Enter
bindkey "^I" expand-or-complete                  # Tab
bindkey "^[[Z" reverse-menu-complete             # Shift+Tab
bindkey "^[[C" forward-char                      # Right
bindkey "^[[1;5C" forward-word                   # Ctrl+Right
bindkey "^[[D" backward-char                     # Left
bindkey "^[[1;5D" backward-word                  # Ctrl+Left
bindkey "^[[H" beginning-of-line                 # Home
bindkey "^[[F" end-of-line                       # End
bindkey "^[[A" up-line-or-history                # Up
bindkey "^[[B" down-line-or-history              # Down
bindkey "^?" backward-delete-char                # Backspace
bindkey "^H" backward-delete-word                # Ctrl+Backspace
bindkey "^[[3~" delete-char                      # Delete
bindkey "^[[3;5~" delete-word                    # Ctrl+Delete
bindkey "^V" quoted-insert                       # Ctrl+V
bindkey "^[[200~" bracketed-paste                # Ctrl+Shift+V
bindkey "^R" history-incremental-search-backward # Ctrl+R
bindkey "^L" clear-screen                        # Ctrl+L
bindkey "^Z" undo                                # Ctrl+Z
bindkey "^Y" redo                                # Ctrl+Y

setopt PUSHD_SILENT

mkdir -p ~/.local/state/zsh
HISTFILE="$HOME/.local/state/zsh/history"
HISTSIZE=9999
SAVEHIST=9999

autoload -Uz compinit
compinit -d ~/.local/state/zsh/compdump

compdef _nothing ntfy
compdef _files ed
compdef _files mkcd
compdef _files mktex
compdef _files mnt
compdef _mk mk
compdef _sm sm
compdef _xh xhs
compdef '_arguments ":cmd:_command_names" "*::args:_normal"' await
compdef '_arguments ":cmd:_command_names" "*::args:_normal"' bw
compdef '_arguments ":cmd:_command_names" "*::args:_normal"' watch

if [[ $HOSTKIND == desktop ]]; then
  compdef _nothing wp-toggle
  compdef _repo repo
fi

_mk() {
  if ((CURRENT == 2)); then
    local sources=(~/.local/share/mk/*)
    if ((${#sources[@]})); then _values source "${sources[@]##*/}"; fi
  elif ((CURRENT == 3)); then
    _files
  fi
}

_repo() {
  local repos=(~/Repos/*)
  repos=("${repos[@]##*/}")

  if ((CURRENT == 2)); then
    _values command help clone edit fetch list remove run shell status update
  elif [[ ${words[2]} == edit ]]; then
    if ((CURRENT == 3)); then
      if ((${#repos[@]})); then _values name "${repos[@]}"; fi
    elif ((CURRENT == 4)); then
      _files -W "$HOME/Repos/${words[3]}"
    fi
  elif [[ ${words[2]} == fetch ]]; then
    if ((CURRENT == 3)); then
      if ((${#repos[@]})); then _values name "${repos[@]}"; fi
    fi
  elif [[ ${words[2]} == remove ]]; then
    if ((CURRENT == 3)); then
      if ((${#repos[@]})); then _values name "${repos[@]}"; fi
    fi
  elif [[ ${words[2]} == run ]]; then
    if ((CURRENT == 3)); then
      if ((${#repos[@]})); then _values name "${repos[@]}"; fi
    else
      compset -n 4
      _normal
    fi
  elif [[ ${words[2]} == shell ]]; then
    if ((CURRENT == 3)); then
      if ((${#repos[@]})); then _values name "${repos[@]}"; fi
    elif ((CURRENT == 4)); then
      _files -/ -W "$HOME/Repos/${words[3]}"
    fi
  elif [[ ${words[2]} == status ]]; then
    if ((CURRENT == 3)); then
      if ((${#repos[@]})); then _values name "${repos[@]}"; fi
    fi
  elif [[ ${words[2]} == update ]]; then
    if ((CURRENT == 3)); then
      if ((${#repos[@]})); then _values name "${repos[@]}"; fi
    fi
  fi
}

_sm() {
  if ((CURRENT == 2)); then
    _values command help edit fix rebuild secrets sync upgrade
  elif [[ ${words[2]} == rebuild ]]; then
    compset -n 2
    _arguments "-h[help]" "-c[clean]" "-d[dry]"
  elif [[ ${words[2]} == secrets ]]; then
    compset -n 2
    _arguments "-h[help]" "-r[rotate]"
  fi
}

if [[ -n ${KITTY_INSTALLATION_DIR:+x} ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration"
  kitty-integration
  unfunction kitty-integration
fi

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
