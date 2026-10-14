compdef _service service

service() {
  if (($#)); then
    docker compose --file "$HOME/docker/$HOSTNAME/$1/compose.yaml" "${@:2}"
  else
    docker container ls --all --format $'\e[2m{{ .ID }}\e[m\t\e[1;34m{{ .Names }}\e[m\t\e[36mCreated {{ .RunningFor }}\e[m\t{{ .Status }}' |
      sed $'s/\tUp .*/\e[32m\\0\e[m/; s/\tExited .*/\e[31m\\0\e[m/; s/\tCreated .*/\e[33m\\0\e[m/' |
      column --table --separator $'\t'
  fi
}

_service() {
  if ((CURRENT == 2)); then
    local services=("$HOME/docker/$HOSTNAME"/*)
    compadd "${services[@]##*/}"
  elif [[ -f $HOME/docker/$HOSTNAME/${words[2]}/compose.yaml ]]; then
    words=("docker" "compose" "--file" "$HOME/docker/$HOSTNAME/${words[2]}/compose.yaml" "${words[3,-1]}")
    CURRENT="$((CURRENT + 2))"
    _docker
  fi
}
