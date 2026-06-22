# fatal <message>
fatal() {
  echo -e "[\e[31mERROR\e[m] $*" >&2
  exit 1
}

# warn <message>
warn() {
  echo -e "[\e[33mWARNING\e[m] $*" >&2
}

# sha [data ...]
sha() {
  if (($#)); then
    echo -n "$*" | sha256sum | cut -d " " -f 1
  else
    sha256sum | cut -d " " -f 1
  fi
}

# load_secrets <store> <target> <key>
load_secrets() {
  local store="$1" target="$2" key="$3"
  gpg --decrypt --quiet --batch --pinentry-mode loopback --passphrase-fd 3 < "$store" 3<<< "$key" | tar x -C "$target"
}

# store_secrets <store> <directory> <key> <spec> ...
store_secrets() {
  local store="$1" directory="$2" key="$3" spec=("${@:4}")
  tar c -C "$directory" "${spec[@]}" | gpg --symmetric --quiet --batch --pinentry-mode loopback --passphrase-fd 3 3<<< "$key" > "$store"
}

# resolve_host <name>
resolve_host() {
  local name="$1" line head key

  while IFS=, read -ra line; do
    if [[ -z ${head:+x} ]]; then
      head=("${line[@]}")
    elif [[ ${line[0]} == "$name" ]]; then
      for key in "${!head[@]}"; do
        export "HOST_${head[key]^^}=${line[key]}"
      done

      return 0
    fi
  done < hosts.csv

  return 1
}

# unmount <path>
unmount() {
  local path="$1"
  if ! mountpoint -q "$path"; then return; fi

  for _ in {0..9}; do
    if umount --recursive "$path"; then return; fi
    sleep 1
  done

  return 1
}
