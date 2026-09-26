#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob
cd ~/Repos

fatal() {
  echo -e "[\e[31mERROR\e[m] $*" >&2
  exit 1
}

resolve() {
  local src="${1%.git}.git"

  for src in "$src" "gh:/$src" "gh:$src" ""; do
    if git ls-remote "$src" &> /dev/null; then
      echo "$src"
      return
    fi
  done
}

enter() {
  if ! cd "$HOME/Repos/$1" 2> /dev/null; then
    fatal "No such repo: $1"
  fi
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

git-is-dirty() {
  [[ $(git status --porcelain) ]]
}

git-has-stash() {
  git rev-parse refs/stash &> /dev/null
}

git-is-local() {
  ! git rev-parse "$1@{upstream}" &> /dev/null
}

git-branches() {
  git for-each-ref --format "%(refname:short)" refs/heads
}

git-status() {
  if git-is-dirty; then echo "changes"; fi
  if git-has-stash; then echo "stash"; fi

  git-branches | while read -r branch; do
    if git-is-local "$branch"; then
      echo "local 0 0 $branch"
    else
      read -r ahead behind < <(git rev-list --left-right --count "$branch...$branch@{upstream}")
      echo "branch $ahead $behind $branch"
    fi
  done
}

help() {
  echo "Usage: repo <command> [args ...]"
  echo
  echo "Commands:"
  echo "  help                   Print this help message"
  echo "  clone <url> [name]     Clone repo"
  echo "  edit <name> [path]     Open editor in repo"
  echo "  fetch [name ...]       Fetch repos"
  echo "  list                   List repos"
  echo "  remove <name>          Remove repo"
  echo "  run <name> <cmd> ...   Run command in repo"
  echo "  shell <name> [path]    Open shell in repo"
  echo "  status <name>          Print status of repo"
  echo "  temp <url>             Open shell in temporary clone"
  echo "  update [name ...]      Update repos"
}

clone() {
  SRC="$(resolve "$1")"
  NAME="${2:-}"

  if [[ ! $SRC ]]; then
    fatal "Not found: $1"
  elif [[ ! $NAME ]]; then
    git clone "$SRC"
  else
    git clone "$SRC" "$NAME"
  fi
}

edit() {
  enter "$1"
  TARGET="${2:-.}"

  if [[ -d $TARGET ]]; then
    exec env -C "$TARGET" "$EDITOR" .
  elif [[ -f $TARGET ]]; then
    exec "$EDITOR" "$TARGET"
  else
    fatal "No such file or directory: $TARGET"
  fi
}

fetch() {
  for repo in "$@"; do
    if [[ -d $repo ]]; then
      git -C "$repo" fetch
    else
      fatal "No such repo: $repo"
    fi
  done
}

list() {
  for repo in *; do
    cd "$repo"

    ICON=""
    URL="$(git-url)"
    HEAD="$(git-head)"

    while read -r type ahead behind _; do
      case "$type" in
        changes) ICON="*" ;;
        stash) if [[ ! $ICON ]]; then ICON="~"; fi ;;
        local) if [[ $ICON != "*" ]]; then ICON="+"; fi ;;
        branch) if [[ $ICON != "*" ]] && ((ahead || behind)); then ICON="+"; fi ;;
      esac
    done < <(git-status)

    case "$HEAD" in
      NULL) printf "\e[1;34m%s \e[0;31m%s\e[36m%s \e[0;2m%s\e[m\n" "$repo" "N/A" "$ICON" "$URL" ;;
      HEAD) printf "\e[1;34m%s \e[0;33m%s\e[36m%s \e[0;2m%s\e[m\n" "$repo" "$(git rev-parse --short HEAD)" "$ICON" "$URL" ;;
      *) printf "\e[1;34m%s \e[0;32m%s\e[36m%s \e[0;2m%s\e[m\n" "$repo" "$HEAD" "$ICON" "$URL" ;;
    esac

    cd ..
  done | column --table
}

remove() {
  NAME="$1"
  enter "$NAME"

  while read -r type ahead behind branch; do
    case "$type" in
      changes) CHANGES+=("Uncommited changes") ;;
      stash) CHANGES+=("Stashed changes") ;;
      local) CHANGES+=("Local branch ($branch)") ;;
      branch) if ((ahead)); then CHANGES+=("Unpushed commits ($branch)"); fi ;;
    esac
  done < <(git-status)

  if ((${#CHANGES[@]})); then
    echo "The repository contains local changes:"
    printf "  - %s\n" "${CHANGES[@]}"
    echo

    read -rp "Are you sure you want to remove this repository? [y/N] "
    if [[ $REPLY != y ]]; then return 1; fi
  fi

  cd ..
  rm -rf "$NAME"
}

run() {
  enter "$1"
  exec "${@:2}"
}

shell() {
  enter "$1"
  exec env -C "${2:-.}" "$SHELL"
}

status() {
  NAME="$1"
  enter "$NAME"

  URL="$(git-url)"
  HEAD="$(git-head)"

  case "$HEAD" in
    NULL) printf "\e[1mRepo: \e[34m%s \e[m(\e[31m%s\e[m, \e[2m%s\e[m)\n" "$NAME" "empty" "$URL" ;;
    HEAD) printf "\e[1mRepo: \e[34m%s \e[m(\e[33m%s\e[m, \e[2m%s\e[m)\n\n" "$NAME" "$(git rev-parse --short HEAD)" "$URL" ;;
    *) printf "\e[1mRepo: \e[34m%s \e[m(\e[32m%s\e[m, \e[2m%s\e[m)\n\n" "$NAME" "$HEAD" "$URL" ;;
  esac

  git-status | while read -r type ahead behind branch; do
    if [[ $branch ]]; then
      read -r hash message < <(git show --oneline --no-patch "$branch")
    fi

    case "$type" in
      local) printf "\e[32m%s\x09\e[36mlocal\x09\e[33m%s \e[m%s\n" "$branch" "$hash" "$message" ;;
      branch) printf "\e[32m%s\x09\e[36m\u2191\e[m%d \e[36m\u2193\e[m%d\x09\e[33m%s \e[m%s\n" "$branch" "$ahead" "$behind" "$hash" "$message" ;;
    esac
  done | column --table --separator $'\x09'

  if git-has-stash; then
    echo
    git stash list --oneline
  fi

  if git-is-dirty; then
    echo
    git status --short
  fi
}

temp() {
  SRC="$(resolve "$1")"
  if [[ ! $SRC ]]; then fatal "Not found: $1"; fi

  trap 'rm -rf "$TMP"' EXIT
  TMP="$(mktemp -d)"

  git clone "$SRC" "$TMP"
  env -C "$TMP" "$SHELL"
}

update() {
  enter "$1"
  STASH=0

  HEAD="$(git-head)"
  if [[ $HEAD == HEAD ]]; then HEAD="$(git rev-parse HEAD)"; fi

  if git-is-dirty; then
    STASH=1
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

  if [[ $HEAD != NULL ]]; then git checkout "$HEAD"; fi
  if ((STASH)); then git stash pop || conflict; fi
}

case "${1:-help}" in
  help) help ;;
  clone | edit | list | remove | run | shell | status | temp) "$@" ;;
  fetch | update) if (($# > 1)); then "$@"; else "$1" ./*; fi ;;
  *) fatal "Illegal command: $1" ;;
esac
