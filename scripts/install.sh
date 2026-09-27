#!/bin/sh
set -eu

REPO="Ladavian/singdeck"
API="https://api.github.com/repos/$REPO"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

fail() {
  printf 'SingDeck 安装失败：%s\n' "$*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || fail "请使用 root 运行，或在命令中保留 sudo"
[ -f /etc/debian_version ] || fail "当前版本仅支持 Debian / PVE LXC"
command -v systemctl >/dev/null 2>&1 || fail "系统必须使用 systemd"

case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) fail "仅支持 AMD64 和 ARM64" ;;
esac

export DEBIAN_FRONTEND=noninteractive
MISSING=""
for CMD in ca-certificates curl jq tar sha256sum; do
  command -v "$CMD" >/dev/null 2>&1 || MISSING="$MISSING $CMD"
done
if [ -n "$MISSING" ]; then
  apt-get update
  apt-get install -y ca-certificates curl jq tar coreutils
fi

install_sing_box() {
  if [ -x /usr/local/bin/sing-box ]; then
    return
  fi
  if command -v sing-box >/dev/null 2>&1; then
    ln -sf "$(command -v sing-box)" /usr/local/bin/sing-box
    return
  fi

  printf '正在从 SagerNet 官方 Release 安装 Sing-box…\n'
  SB_JSON=$(curl -fsSL --retry 3 "https://api.github.com/repos/SagerNet/sing-box/releases/latest")
  SB_TAG=$(printf '%s' "$SB_JSON" | jq -r '.tag_name')
  SB_VERSION=${SB_TAG#v}
  SB_NAME="sing-box-${SB_VERSION}-linux-${ARCH}.tar.gz"
  SB_URL=$(printf '%s' "$SB_JSON" | jq -r --arg name "$SB_NAME" '.assets[] | select(.name == $name) | .browser_download_url')
  SB_DIGEST=$(printf '%s' "$SB_JSON" | jq -r --arg name "$SB_NAME" '.assets[] | select(.name == $name) | .digest' | sed 's/^sha256://')
  [ -n "$SB_URL" ] && [ "$SB_URL" != "null" ] || fail "官方 Release 中没有找到 $SB_NAME"
  [ -n "$SB_DIGEST" ] && [ "$SB_DIGEST" != "null" ] || fail "官方 Release 未提供 Sing-box SHA256"
  curl -fL --retry 3 -o "$TMP_DIR/$SB_NAME" "$SB_URL"
  printf '%s  %s\n' "$SB_DIGEST" "$TMP_DIR/$SB_NAME" | sha256sum -c -
  mkdir -p "$TMP_DIR/sing-box"
  tar -xzf "$TMP_DIR/$SB_NAME" -C "$TMP_DIR/sing-box"
  SB_BIN=$(find "$TMP_DIR/sing-box" -type f -name sing-box | head -n 1)
  [ -n "$SB_BIN" ] || fail "Sing-box 安装包中未找到程序文件"
  install -m 0755 "$SB_BIN" /usr/local/bin/sing-box
}

if [ "${SINGDECK_VERSION:-latest}" = "latest" ]; then
  RELEASE_JSON=$(curl -fsSL --retry 3 "$API/releases/latest")
  VERSION=$(printf '%s' "$RELEASE_JSON" | jq -r '.tag_name')
else
  VERSION=$SINGDECK_VERSION
fi

case "$VERSION" in
  v*) ;;
  *) fail "版本号必须使用 v 开头，例如 v0.3.1" ;;
esac

ASSET="singdeck-${VERSION}-linux-${ARCH}.tar.gz"
BASE_URL="https://github.com/$REPO/releases/download/$VERSION"

printf '正在下载 SingDeck %s (%s)…\n' "$VERSION" "$ARCH"
curl -fL --retry 3 -o "$TMP_DIR/$ASSET" "$BASE_URL/$ASSET"
curl -fL --retry 3 -o "$TMP_DIR/$ASSET.sha256" "$BASE_URL/$ASSET.sha256"
(cd "$TMP_DIR" && sha256sum -c "$ASSET.sha256")

mkdir -p "$TMP_DIR/singdeck"
tar -xzf "$TMP_DIR/$ASSET" -C "$TMP_DIR/singdeck"
[ -x "$TMP_DIR/singdeck/singdeck" ] || fail "安装包内容不完整"

install_sing_box

if systemctl is-active --quiet singdeck.service 2>/dev/null; then
  systemctl stop singdeck.service
fi

install -d -m 0750 /etc/singdeck /etc/sing-box /var/lib/singdeck /var/lib/sing-box
install -m 0755 "$TMP_DIR/singdeck/singdeck" /usr/local/bin/singdeck

if [ ! -f /etc/singdeck/singdeck.env ]; then
  PASSWORD=$(od -An -N18 -tx1 /dev/urandom | tr -d ' \n')
  umask 077
  printf 'SINGDECK_ADMIN_PASSWORD=%s\n' "$PASSWORD" > /etc/singdeck/singdeck.env
fi

cat > /etc/systemd/system/singdeck.service <<'EOF'
[Unit]
Description=SingDeck Web Control Plane
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
EnvironmentFile=-/etc/singdeck/singdeck.env
ExecStart=/usr/local/bin/singdeck --listen 0.0.0.0:8080 --data-dir /var/lib/singdeck --sing-box /usr/local/bin/sing-box --config /etc/sing-box/config.json
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/singdeck /etc/sing-box
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

if [ ! -f /etc/systemd/system/sing-box.service ]; then
  cat > /etc/systemd/system/sing-box.service <<'EOF'
[Unit]
Description=sing-box Service managed by SingDeck
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload
systemctl enable --now singdeck.service

HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -n "$HOST_IP" ] || HOST_IP="服务器IP"

printf '\nSingDeck %s 安装完成。\n' "$VERSION"
printf '访问地址：http://%s:8080\n' "$HOST_IP"
printf '用户名：admin\n'
printf '初始密码：%s\n' "$(sed -n 's/^SINGDECK_ADMIN_PASSWORD=//p' /etc/singdeck/singdeck.env)"
printf '请妥善保存密码，并优先通过可信内网或 HTTPS 访问。\n'
