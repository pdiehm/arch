compdef _service service

service() {
  if (($#)); then
    docker compose --file "$HOME/docker/$HOSTNAME/$1/compose.yaml" "${@:2}"
  else
    docker container ls --all --format $'\e[2m{{ .ID }}\e[m\x09\e[1;34m{{ .Names }}\e[m\x09\e[36mCreated {{ .RunningFor }}\e[m\x09{{ .Status }}' |
      sed $'s/\x09Up .*/\e[32m\\0\e[m/; s/\x09Exited .*/\e[31m\\0\e[m/; s/\x09Created .*/\e[33m\\0\e[m/' |
      column --table --separator $'\x09'
  fi
}

_service() {
  if ((CURRENT == 2)); then
    local cmp=("$HOME/docker/$HOSTNAME"/*)
    compadd "${cmp[@]##*/}"
  elif [[ -f $HOME/docker/$HOSTNAME/${words[2]}/compose.yaml ]]; then
    words=("docker" "compose" "--file" "$HOME/docker/$HOSTNAME/${words[2]}/compose.yaml" "${words[3,-1]}")
    CURRENT="$((CURRENT + 2))"
    _docker
  fi
}
