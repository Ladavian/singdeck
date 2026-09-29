#!/bin/sh
set -eu

TMP_SCRIPT=$(mktemp)
trap 'rm -f "$TMP_SCRIPT"' EXIT INT TERM
INSTALL_REF=${SINGDECK_INSTALL_REF:-0296e245df6902c8b6d19c1e1bcf629172e76867}
INSTALL_URL="https://raw.githubusercontent.com/Ladavian/singdeck/$INSTALL_REF/scripts/install.sh"
if [ -n "${GITHUB_PROXY:-}" ]; then
  case "$GITHUB_PROXY" in
    http://*|https://*) INSTALL_URL="${GITHUB_PROXY%/}/$INSTALL_URL" ;;
    *) printf 'GITHUB_PROXY 必须是以 http:// 或 https:// 开头的地址\n' >&2; exit 1 ;;
  esac
fi
export GITHUB_PROXY
curl -fsSL --retry 3 -o "$TMP_SCRIPT" "$INSTALL_URL"
sh "$TMP_SCRIPT" "$@"
