compdef _nothing genpw
compdef _nothing wp-toggle
compdef _mk mk
compdef _mnt mnt
compdef _repo repo
compdef _tldr tl
compdef '_arguments ":cmd:(power discoverable)"' bt-toggle
compdef '_arguments ":cmd:_command_names" "*::args:_normal"' bw

alias mktex='latexmk -cd -pdf -outdir="$PWD/build"'
alias open="xdg-open"
alias play="mpv --no-audio-display"
alias py="python3"

man() {
  if (($#)); then
    /usr/bin/man "$@"
  else
    local width="$((COLUMNS / 2))"

    /usr/bin/man -k . |
      sed -E "s/^(\S+) \((\S+)\).*/\1.\2/" |
      fzf --preview "MANWIDTH='$width' man {} 2> /dev/null | bat --plain --language man --color always" --preview-window "$width" |
      xargs -r /usr/bin/man
  fi
}

tl() {
  if (($#)); then
    tldr "$@"
  else
    tldr --list | fzf --preview "tldr --color always {}" --preview-window 80% | xargs -r tldr
  fi
}

_mk() {
  if ((CURRENT == 2)); then
    local cmp=(~/.local/share/mk/*)
    compadd "${cmp[@]##*/}"
  elif ((CURRENT == 3)); then
    _files
  fi
}

_mnt() {
  if ((CURRENT == 2)); then
    local cmp=("tmpfs" "android" /dev/{sd,hd,md,vd,sr,nvme,loop}* /dev/disk/by-label/* /dev/disk/by-partlabel/*)
    compadd "${cmp[@]##*/}"
    compadd -S "" "ssh://"
    _files
  fi
}

_repo() {
  local repos=(~/Repos/*)
  repos=("${repos[@]##*/}")

  if ((CURRENT == 2)); then
    compadd help clone edit fetch list remove run shell status update
  elif [[ ${words[2]} == edit ]]; then
    if ((CURRENT == 3)); then
      compadd "${repos[@]}"
    elif ((CURRENT == 4)); then
      _files -W "$HOME/Repos/${words[3]}"
    fi
  elif [[ ${words[2]} == fetch ]]; then
    if ((CURRENT == 3)); then compadd "${repos[@]}"; fi
  elif [[ ${words[2]} == remove ]]; then
    if ((CURRENT == 3)); then compadd "${repos[@]}"; fi
  elif [[ ${words[2]} == run ]]; then
    if ((CURRENT == 3)); then
      compadd "${repos[@]}"
    else
      compset -n 4
      _normal
    fi
  elif [[ ${words[2]} == shell ]]; then
    if ((CURRENT == 3)); then
      compadd "${repos[@]}"
    elif ((CURRENT == 4)); then
      _files -/ -W "$HOME/Repos/${words[3]}"
    fi
  elif [[ ${words[2]} == status ]]; then
    if ((CURRENT == 3)); then compadd "${repos[@]}"; fi
  elif [[ ${words[2]} == update ]]; then
    if ((CURRENT == 3)); then compadd "${repos[@]}"; fi
  fi
}

if [[ ${KITTY_INSTALLATION_DIR:+x} ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration"
  kitty-integration
  unfunction kitty-integration
fi
