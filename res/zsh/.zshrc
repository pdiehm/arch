# shellcheck disable=SC1090,SC1094,SC2034,SC2140,SC2154,SC2155,SC2164

PROMPT='%F{4}%~%f$(_prompt_git) %F{%(?.5.1)}$(_prompt_char)%f '
RPROMPT='$(_prompt_host)'

setopt PROMPT_SUBST
setopt PUSHD_SILENT
setopt SHARE_HISTORY

mkdir -p ~/.local/state/zsh
HISTFILE="$HOME/.local/state/zsh/history"
HISTSIZE=9999
SAVEHIST=9999

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

autoload -Uz compinit
compinit -d ~/.local/state/zsh/compdump

compdef _nothing ntfy
compdef _files ed
compdef _files mkcd
compdef _sm sm
compdef _xh xhs
compdef '_arguments ":cmd:_command_names" "*::args:_normal"' await
compdef '_arguments ":cmd:_command_names" "*::args:_normal"' watch

alias dog="doggo"
alias fd="fd --follow --hidden"
alias l="ls --all --long --group"
alias ls="eza"
alias lsblk="lsblk --output NAME,TYPE,SIZE,VENDOR,MODEL,PTTYPE,PARTLABEL,PARTTYPENAME,LABEL,FSTYPE,MOUNTPOINTS"
alias ntfy="ntfy -c main"
alias parallel="parallel --group --keep-order"
alias rg="rg --follow --hidden --smart-case"
alias tx="tmux new -As main"
alias type="type -as"

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

watch() (
  trap "printf '\e[?25h\e[?1049l'" EXIT
  trap "exit 0" INT
  printf "\e[?25l\e[?1049h"

  while true; do
    echo -e "\e[H\e[2mWatching: $*\e[m\n"
    printf "\e[J%s\n" "$(script --quiet --command "zsh --interactive -c $(printf "%q" "$*")" /dev/null)"
    sleep 1
  done
)

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

  local staged="$(git diff --staged --name-only)"
  local changed="$(git ls-files --modified --others --exclude-standard)"

  if [[ $staged && $changed ]]; then
    echo -en "%F{6}\u203d%f"
  elif [[ $staged ]]; then
    echo -n "%F{6}!%f"
  elif [[ $changed ]]; then
    echo -n "%F{6}?%f"
  fi

  if [[ $(git stash list) ]]; then
    echo -en " %F{6}\u2026%f"
  fi

  if [[ $(git remote show) && $branch != HEAD ]]; then
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
  elif [[ -d $git/rebase-merge ]]; then
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
  if [[ ${SSH_TTY:+x} ]]; then
    echo -n "%F{14}%n@%M%f"
  fi
}

_sm() {
  if ((CURRENT == 2)); then
    compadd help edit fix rebuild secrets sync upgrade
  elif [[ ${words[2]} == rebuild ]]; then
    compset -n 2
    _arguments "-h[help]" "-b[break]" "-c[clean]" "-n[dry]"
  elif [[ ${words[2]} == secrets ]]; then
    compset -n 2
    _arguments "-h[help]" "-r[rotate]"
  fi
}

source "$HOME/.config/zsh/$HOSTKIND.zsh"
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
