#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob
cd ~/Repos

fatal() {
  echo -e "[\e[31mERROR\e[m] $*" >&2
  exit 1
}

enter() {
  local name="$1"
  if [[ ! -d $name ]]; then fatal "Repo '$name' not found"; fi
  cd "$name"
}

conflict() {
  git status
  read -rp "Press enter to open editor..."

  if ! "$EDITOR" .; then
    fatal "Editor exited with non-zero status, aborting..."
  fi
}

git-url() {
  if ! git remote get-url origin 2> /dev/null; then
    printf "local"
  fi
}

git-head() {
  if git rev-parse HEAD &> /dev/null; then
    git rev-parse --abbrev-ref HEAD
  else
    printf "NULL"
  fi
}

git-is-local() {
  local branch="$1"
  if git rev-parse "$branch@{upstream}" &> /dev/null; then return 1; else return 0; fi
}

git-branches() {
  git for-each-ref --format "%(refname:short)" refs/heads
}

git-status() {
  if [[ -n "$(git status --porcelain)" ]]; then printf "change\n"; fi
  if [[ -n "$(git stash list)" ]]; then printf "stash\n"; fi

  local branch ahead behind
  while read -r branch; do
    if git-is-local "$branch"; then
      printf "local 0 0 %s\n" "$branch"
    else
      ahead="$(git rev-list --count "$branch@{upstream}..$branch")"
      behind="$(git rev-list --count "$branch..$branch@{upstream}")"
      printf "branch %d %d %s\n" "$ahead" "$behind" "$branch"
    fi
  done < <(git-branches)
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
  echo "  run <name> <cmd ...>    Run command in repo"
  echo "  shell <name> [path]     Open shell in repo"
  echo "  status [name]           Print status of repo(s)"
  echo "  update [name]           Update repo(s)"
}

clone() {
  local url="$1" name="${2:-}"

  if [[ -z $name ]]; then
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
  elif [[ -e $path ]]; then
    cd "$(dirname "$path")"
    exec "$EDITOR" "$(basename "$path")"
  else
    fatal "Path '$path' not found"
  fi
}

fetch() {
  local name="${1:-}"

  if [[ -z $name ]]; then
    for name in *; do fetch "$name"; done
  elif [[ ! -d $name ]]; then
    fatal "Repo '$name' not found"
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
      echo -e "\e[1;34m$repo \e[0;31mN/A \e[0;2m$url\e[m"
    elif [[ $head == HEAD ]]; then
      echo -e "\e[1;34m$repo \e[0;33m$(git rev-parse --short HEAD) \e[0;2m$url\e[m"
    else
      local icon=""

      while read -r type ahead behind _; do
        case "$type" in
          change) icon="*" ;;
          stash) if [[ -z $icon ]]; then icon="~"; fi ;;
          local) if [[ $icon != "*" ]]; then icon="+"; fi ;;
          branch) if [[ $icon != "*" ]] && ((ahead || behind)); then icon="+"; fi ;;
        esac
      done < <(git-status)

      echo -e "\e[1;34m$repo \e[0;32m$head\e[36m$icon \e[0;2m$url\e[m"
    fi

    cd ..
  done | column --table
}

remove() {
  local name="$1"
  enter "$name"

  local changes=()
  while read -r state ahead behind branch; do
    case "$state" in
      change) changes+=("Uncommited changes") ;;
      stash) changes+=("Stashed changes") ;;
      local) changes+=("Local branch ($branch)") ;;
      branch) if ((ahead)); then changes+=("Unpushed commits ($branch)"); fi ;;
    esac
  done < <(git-status)

  if ((${#changes[@]})); then
    echo "The repository contains local changes:"
    for change in "${changes[@]}"; do echo "  - $change"; done
    echo

    read -rp "Are you sure you want to remove this repository? [y/N] " read
    if [[ $read != y ]]; then exit 1; fi
  fi

  cd ..
  rm -rf "$name"
}

run() {
  local name="$1" cmd=("${@:2}")
  if ((${#cmd[@]} == 0)); then fatal "Usage: repo run <name> <cmd ...>"; fi

  enter "$name"
  exec "${cmd[@]}"
}

shell() {
  local name="$1" path="${2:-.}"
  enter "$name"

  if [[ ! -d $path ]]; then fatal "Path '$path' not found"; fi
  cd "$path"

  exec "$SHELL"
}

status() {
  local name="${1:-}"

  if [[ -z $name ]]; then
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
    echo -e "\e[1mRepo: \e[34m$name \e[m(\e[31mempty\e[m, \e[2m$url\e[m)\n"
  elif [[ $head == HEAD ]]; then
    echo -e "\e[1mRepo: \e[34m$name \e[m(\e[33m$(git rev-parse --short HEAD)\e[m, \e[2m$url\e[m)\n"
  else
    echo -e "\e[1mRepo: \e[34m$name \e[m(\e[32m$head\e[m, \e[2m$url\e[m)\n"
  fi

  git-status | while read -r state ahead behind branch; do
    if [[ -n $branch ]]; then
      read -r hash message <<< "$(git show --oneline --no-patch "$branch")"
    fi

    case "$state" in
      local) echo -e "\e[32m$branch\x09\e[36mlocal\x09\e[33m$hash \e[m$message" ;;
      branch) echo -e "\e[32m$branch\x09\e[36m\u2191\e[m$ahead \e[36m\u2193\e[m$behind\x09\e[33m$hash \e[m$message" ;;
    esac
  done | column --table --separator $'\x09'

  if [[ -n "$(git stash list)" ]]; then echo && git stash list --oneline; fi
  if [[ -n "$(git status --porcelain)" ]]; then echo && git status --short; fi
  cd ..
}

update() {
  local name="${1:-}"

  if [[ -z $name ]]; then
    for name in *; do update "$name"; done
    return
  fi

  enter "$name"
  git fetch

  stashed="$(git status --porcelain | wc -l)"
  if ((stashed)); then git stash push --include-untracked; fi

  head="$(git-head)"
  if [[ $head == HEAD ]]; then head="$(git rev-parse HEAD)"; fi

  git-branches | while read -r branch; do
    if git-is-local "$branch"; then continue; fi
    git checkout "$branch"

    if [[ -n "$(git status --porcelain)" ]]; then
      git stash push --include-untracked
      git pull || conflict
      git stash pop || conflict
    else
      git pull || conflict
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
  *) fatal "Unknown command: $1" ;;
esac
