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

# encode_secret [data ...]
encode_secret() {
  if (($#)); then
    echo -n "$*" | base64 -w 0
  else
    base64 -w 0
  fi
}

# decode_secret [data ...]
decode_secret() {
  if (($#)); then
    echo -n "$*" | base64 -d
  else
    base64 -d
  fi
}

# load_secrets <src> <dst> <key>
load_secrets() {
  local src="$1" dst="$2" key="$3"
  gpg --decrypt --quiet --batch --pinentry-mode loopback --passphrase-fd 0 --output "$dst" "$src" <<< "$key"
}

# save_secrets <src> <dst> <key>
save_secrets() {
  local src="$1" dst="$2" key="$3"
  gpg --symmetric --quiet --batch --pinentry-mode loopback --passphrase-fd 0 --output "$dst" "$src" <<< "$key"
}

# resolve_host <name>
resolve_host() {
  local name="$1" line head

  while IFS=, read -ra line; do
    if [[ -z ${head:+x} ]]; then
      head=("${line[@]}")
    elif [[ ${line[0]} == "$name" ]]; then
      local key
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
