#!/usr/bin/env bash

SYLLABLES=(
  "ba" "be" "bi" "bo" "bu"
  "fa" "fe" "fi" "fo" "fu"
  "ga" "ge" "gi" "go" "gu"
  "ka" "ke" "ki" "ko" "ku"
  "la" "le" "li" "lo" "lu"
  "ma" "me" "mi" "mo" "mu"
  "na" "ne" "ni" "no" "nu"
  "pa" "pe" "pi" "po" "pu"
  "ra" "re" "ri" "ro" "ru"
  "sa" "se" "si" "so" "su"
  "ta" "te" "ti" "to" "tu"
  "wa" "we" "wi" "wo" "wu"
  "ja" "je" "jo" "ju"
)

HELP=0
ENTROPY=270
WORDLEN=3

while getopts "he:w:" opt; do
  case "$opt" in
    h) HELP=1 ;;
    e) ENTROPY="$OPTARG" ;;
    w) WORDLEN="$OPTARG" ;;
    *) exit 1 ;;
  esac
done

if ((HELP)); then
  echo "Usage: genpw [-e entropy] [-w wordlen]"
  echo
  echo "Options:"
  echo "  -h   Print this help message"
  echo "  -e   Set entropy (bits)"
  echo "  -w   Set word length (syllables per word)"
  exit
fi

for ((i = 0; i < ENTROPY; i += 6)); do
  if ((i > 0 && i % (WORDLEN * 6) == 0)); then echo -n " "; fi
  echo -n "${SYLLABLES[SRANDOM % 64]}"
done
