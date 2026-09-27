#!/bin/sh
set -eu

PURGE=0
if [ "${1:-}" = "--purge" ]; then
  PURGE=1
fi

if [ "$(id -u)" -ne 0 ]; then
  printf '请使用 root 运行，或在命令中保留 sudo\n' >&2
  exit 1
fi

systemctl disable --now singdeck.service 2>/dev/null || true
rm -f /etc/systemd/system/singdeck.service /usr/local/bin/singdeck
systemctl daemon-reload

if [ "$PURGE" -eq 1 ]; then
  rm -rf /etc/singdeck /var/lib/singdeck
  printf 'SingDeck 程序、数据库和设置已删除。\n'
else
  printf 'SingDeck 程序已卸载，数据库和设置仍保留在 /var/lib/singdeck 与 /etc/singdeck。\n'
fi

printf 'Sing-box 核心和 /etc/sing-box 未删除。\n'
