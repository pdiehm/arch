#!/usr/bin/env bash

help=0
channel="$HOSTNAME"
priority="default"
title=""

while getopts "hc:p:t:" opt; do
  case "$opt" in
    h) help=1 ;;
    c) channel="$OPTARG" ;;
    p) priority="$OPTARG" ;;
    t) title="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

shift $((OPTIND - 1))

if ((help)); then
  echo "Usage: ntfy [-c channel] [-p priority] [-t title] <message> ..."
  echo
  echo "Options:"
  echo "  -h   Print this help message"
  echo "  -c   Set channel"
  echo "  -p   Set priority (min/low/default/high/max)"
  echo "  -t   Set title"
  exit
fi

if (($#)); then
  curl -fsSL -H "Authorization: Bearer $(< /usr/local/share/ntfy/token)" -H "Priority: $priority" ${title:+-H "Title: $title"} -d "$*" "https://ntfy.pdiehm.dev/$channel"
else
  echo "Usage: ntfy [-c channel] [-p priority] [-t title] <message> ..."
  exit 1
fi
