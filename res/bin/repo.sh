#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob
cd ~/Repos

fatal() {
  echo -e "[\e[31mERROR\e[m] $*" >&2
  exit 1
}

enter() {
  if [[ ! -d $1 ]]; then fatal "No such repo: $1"; fi
  cd "$1"
}

conflict() {
  git status
  read -rsp "Press enter to open editor..."

  if ! "$EDITOR" .; then
    fatal "Editor exited with non-zero status, aborting..."
  fi
}

git-url() {
  if ! git remote get-url origin 2> /dev/null; then
    echo "local"
  fi
}

git-head() {
  if git rev-parse HEAD &> /dev/null; then
    git rev-parse --abbrev-ref HEAD
  else
    echo "NULL"
  fi
}

git-is-local() {
  if git rev-parse "$1@{upstream}" &> /dev/null; then return 1; else return 0; fi
}

git-is-dirty() {
  if [[ $(git diff --staged --name-only) ]]; then return 0; fi
  if [[ $(git ls-files --modified --others --exclude-standard) ]]; then return 0; fi
  return 1
}

git-branches() {
  git for-each-ref --format "%(refname:short)" refs/heads
}

git-status() {
  if git-is-dirty; then echo "change"; fi
  if [[ $(git stash list) ]]; then echo "stash"; fi

  local branch
  git-branches | while read -r branch; do
    if git-is-local "$branch"; then
      echo "local 0 0 $branch"
    else
      ahead="$(git rev-list --count "$branch@{upstream}..$branch")"
      behind="$(git rev-list --count "$branch..$branch@{upstream}")"
      echo "branch $ahead $behind $branch"
    fi
  done
}

help() {
  echo "Usage: repo <command> [args ...]"
  echo
  echo "Commands:"
  echo "  help                    Print this help message"
  echo "  clone <url> [name]      Clone repo"
  echo "  edit <name> [path]      Open editor in repo"
  echo "  fetch [name]            Fetch repo(s)"
  echo "  list                    List repos"
  echo "  remove <name>           Remove repo"
  echo "  run <name> <cmd> ...    Run command in repo"
  echo "  shell <name> [path]     Open shell in repo"
  echo "  status [name]           Print status of repo(s)"
  echo "  update [name]           Update repo(s)"
}

clone() {
  local src="${1%.git}.git" name="${2:-}"

  for url in "$src" "gh:/$src" "gh:$src" ""; do
    if git ls-remote "$url" &> /dev/null; then break; fi
  done

  if [[ ! $url ]]; then
    fatal "Not found: $src"
  elif [[ ! $name ]]; then
    git clone "$url"
  else
    git clone "$url" "$name"
  fi
}

edit() {
  local name="$1" path="${2:-.}"
  enter "$name"

  if [[ -d $path ]]; then
    cd "$path"
    exec "$EDITOR" .
  elif [[ -f $path ]]; then
    cd "$(dirname "$path")"
    exec "$EDITOR" "$(basename "$path")"
  else
    fatal "No such file or directory: $path"
  fi
}

fetch() {
  local name="${1:-}"

  if [[ ! $name ]]; then
    for name in *; do fetch "$name"; done
  elif [[ ! -d $name ]]; then
    fatal "No such repo: $name"
  else
    git -C "$name" fetch
  fi
}

list() {
  for repo in *; do
    cd "$repo"
    url="$(git-url)"
    head="$(git-head)"

    if [[ $head == NULL ]]; then
      printf "\e[1;34m%s \e[0;31m%s \e[0;2m%s\e[m\n" "$repo" "N/A" "$url"
    elif [[ $head == HEAD ]]; then
      printf "\e[1;34m%s \e[0;33m%s \e[0;2m%s\e[m\n" "$repo" "$(git rev-parse --short HEAD)" "$url"
    else
      local icon=""

      while read -r type ahead behind _; do
        case "$type" in
          change) icon="*" ;;
          stash) if [[ ! $icon ]]; then icon="~"; fi ;;
          local) if [[ $icon != "*" ]]; then icon="+"; fi ;;
          branch) if [[ $icon != "*" ]] && ((ahead || behind)); then icon="+"; fi ;;
        esac
      done < <(git-status)

      printf "\e[1;34m%s \e[0;32m%s\e[36m%s \e[0;2m%s\e[m\n" "$repo" "$head" "$icon" "$url"
    fi

    cd ..
  done | column --table
}

remove() {
  local name="$1"
  enter "$name"

  local changes=()
  while read -r type ahead behind branch; do
    case "$type" in
      change) changes+=("Uncommited changes") ;;
      stash) changes+=("Stashed changes") ;;
      local) changes+=("Local branch ($branch)") ;;
      branch) if ((ahead)); then changes+=("Unpushed commits ($branch)"); fi ;;
    esac
  done < <(git-status)

  if ((${#changes[@]})); then
    echo "The repository contains local changes:"
    printf "  - %s\n" "${changes[@]}"
    echo

    read -rp "Are you sure you want to remove this repository? [y/N] "
    if [[ $REPLY != y ]]; then exit 1; fi
  fi

  cd ..
  rm -rf "$name"
}

run() {
  local name="$1" cmd=("${@:2}")
  if ((${#cmd[@]} == 0)); then fatal "Usage: repo run <name> <cmd> ..."; fi

  enter "$name"
  exec "${cmd[@]}"
}

shell() {
  local name="$1" path="${2:-.}"
  enter "$name"

  if [[ ! -d $path ]]; then fatal "No such directory: $path"; fi
  cd "$path"

  exec "$SHELL"
}

status() {
  local name="${1:-}"

  if [[ ! $name ]]; then
    local div=0

    for name in *; do
      if ((div)); then echo -e "\n\n"; fi
      status "$name"
      div=1
    done

    return
  fi

  enter "$name"
  url="$(git-url)"
  head="$(git-head)"

  if [[ $head == NULL ]]; then
    printf "\e[1mRepo: \e[34m%s \e[m(\e[31m%s\e[m, \e[2m%s\e[m)\n\n" "$name" "empty" "$url"
  elif [[ $head == HEAD ]]; then
    printf "\e[1mRepo: \e[34m%s \e[m(\e[33m%s\e[m, \e[2m%s\e[m)\n\n" "$name" "$(git rev-parse --short HEAD)" "$url"
  else
    printf "\e[1mRepo: \e[34m%s \e[m(\e[32m%s\e[m, \e[2m%s\e[m)\n\n" "$name" "$head" "$url"
  fi

  git-status | while read -r type ahead behind branch; do
    if [[ $branch ]]; then
      read -r hash message < <(git show --oneline --no-patch "$branch")
    fi

    case "$type" in
      local) printf "\e[32m%s\x09\e[36mlocal\x09\e[33m%s \e[m%s\n" "$branch" "$hash" "$message" ;;
      branch) printf "\e[32m%s\x09\e[36m\u2191\e[m%d \e[36m\u2193\e[m%d\x09\e[33m%s \e[m%s\n" "$branch" "$ahead" "$behind" "$hash" "$message" ;;
    esac
  done | column --table --separator $'\x09'

  if [[ $(git stash list) ]]; then echo && git stash list --oneline; fi
  if git-is-dirty; then echo && git status --short; fi
  cd ..
}

update() {
  local name="${1:-}"

  if [[ ! $name ]]; then
    for name in *; do update "$name"; done
    return
  fi

  enter "$name"
  head="$(git-head)"
  if [[ $head == HEAD ]]; then head="$(git rev-parse HEAD)"; fi

  local stashed=0
  if git-is-dirty; then
    stashed=1
    git stash push --include-untracked
  fi

  git-branches | while read -r branch; do
    if git-is-local "$branch"; then continue; fi
    git checkout "$branch"

    if git-is-dirty; then
      git stash push --include-untracked
      git pull --recurse-submodules=on-demand || conflict
      git stash pop || conflict
    else
      git pull --recurse-submodules=on-demand || conflict
    fi
  done

  if [[ $head != NULL ]]; then git checkout "$head"; fi
  if ((stashed)); then git stash pop || conflict; fi
  cd ..
}

if (($# == 0)); then
  help
  exit 1
fi

case "$1" in
  help) help ;;
  clone) clone "${@:2}" ;;
  edit) edit "${@:2}" ;;
  fetch) fetch "${@:2}" ;;
  list) list ;;
  remove) remove "${@:2}" ;;
  run) run "${@:2}" ;;
  shell) shell "${@:2}" ;;
  status) status "${@:2}" ;;
  update) update "${@:2}" ;;
  *) fatal "Illegal command: $1" ;;
esac
