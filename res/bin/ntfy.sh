#!/usr/bin/env bash

HELP=0
CHANNEL="$HOSTNAME"
PRIORITY=""
TITLE=""

while getopts "hc:p:t:" opt; do
  case "$opt" in
    h) HELP=1 ;;
    c) CHANNEL="$OPTARG" ;;
    p) PRIORITY="$OPTARG" ;;
    t) TITLE="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

shift "$((OPTIND - 1))"

if ((HELP)); then
  echo "Usage: ntfy [-c channel] [-p priority] [-t title] <message> ..."
  echo
  echo "Options:"
  echo "  -h   Print this help message"
  echo "  -c   Set channel"
  echo "  -p   Set priority (min/low/default/high/max)"
  echo "  -t   Set title"
  exit
fi

if (($# == 0)); then
  echo "Usage: ntfy [-c channel] [-p priority] [-t title] <message> ..."
  exit 1
fi

curl -fsSL -d "$*" \
  -H "Authorization: Bearer $(< /usr/local/lib/ntfy/token)" \
  ${PRIORITY:+-H "Priority: $PRIORITY"} \
  ${TITLE:+-H "Title: $TITLE"} \
  "https://ntfy.pdiehm.dev/$CHANNEL"
