#!/bin/sh
set -eu

TMP_SCRIPT=$(mktemp)
trap 'rm -f "$TMP_SCRIPT"' EXIT INT TERM
curl -fsSL --retry 3 -o "$TMP_SCRIPT" https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/install.sh
sh "$TMP_SCRIPT" "$@"
