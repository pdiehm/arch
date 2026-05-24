#!/usr/bin/env bash

help=0
priority="default"

while getopts "hp:" opt; do
  case "$opt" in
    h) help=1 ;;
    p) priority="$OPTARG" ;;

    *)
      echo "Invalid option: -$opt"
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if ((help)); then
  echo "Usage: ntfy [-p priority] <message ...>"
  echo
  echo "Options:"
  echo "  -h   Print this help message"
  echo "  -p   Set priority (min/low/default/high/max)"
  exit
fi

if (($#)); then
  curl -fsSL -H "Authorization: Bearer $(< /usr/local/lib/ntfy/token)" -H "Priority: $priority" -d "$*" "https://ntfy.pdiehm.dev/$HOSTNAME"
else
  echo "Usage: ntfy [-p priority] <message ...>"
  exit 1
fi
