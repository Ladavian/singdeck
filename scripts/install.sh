#!/bin/sh
set -eu

REPO="Ladavian/singdeck"
LATEST_SINGDECK_VERSION="v0.3.6"
SING_BOX_VERSION="1.14.2"
GITHUB_PROXY=${GITHUB_PROXY:-}
GITHUB_PROXY_NONCE=$(date +%s)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

fail() {
  printf 'SingDeck 安装失败：%s\n' "$*" >&2
  exit 1
}

github_url() {
  TARGET_URL=$1
  if [ -n "$GITHUB_PROXY" ]; then
    case "$TARGET_URL" in
      *\?*) QUERY_SEPARATOR='&' ;;
      *) QUERY_SEPARATOR='?' ;;
    esac
    printf '%s/%s%ssingdeck=%s\n' "${GITHUB_PROXY%/}" "$TARGET_URL" "$QUERY_SEPARATOR" "$GITHUB_PROXY_NONCE"
  else
    printf '%s\n' "$TARGET_URL"
  fi
}

case "$GITHUB_PROXY" in
  ""|http://*|https://*) ;;
  *) fail "GITHUB_PROXY 必须是以 http:// 或 https:// 开头的地址" ;;
esac

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
for CMD in curl tar sha256sum nft ip sysctl; do
  command -v "$CMD" >/dev/null 2>&1 || MISSING="$MISSING $CMD"
done
if [ ! -r /etc/ssl/certs/ca-certificates.crt ]; then
  MISSING="$MISSING ca-certificates"
fi
if [ -n "$MISSING" ]; then
  apt-get update
  apt-get install -y ca-certificates curl tar coreutils nftables iproute2 procps
fi

sing_box_compatible() {
  BIN=$1
  [ -x "$BIN" ] || return 1
  CURRENT=$($BIN version 2>/dev/null | sed -n 's/^sing-box version v*\([0-9][0-9.]*\).*$/\1/p' | head -n 1)
  [ -n "$CURRENT" ] || return 1
  FIRST=$(printf '%s\n%s\n' 1.14.0 "$CURRENT" | sort -V | head -n 1)
  [ "$FIRST" = "1.14.0" ]
}

install_sing_box() {
  if sing_box_compatible /usr/local/bin/sing-box; then
    return
  fi
  SYSTEM_BIN=$(command -v sing-box 2>/dev/null || true)
  if [ -n "$SYSTEM_BIN" ] && [ "$SYSTEM_BIN" != "/usr/local/bin/sing-box" ] && sing_box_compatible "$SYSTEM_BIN"; then
    install -m 0755 "$SYSTEM_BIN" /usr/local/bin/sing-box
    return
  fi

  printf '正在从 SagerNet 官方 Release 安装 Sing-box %s…\n' "$SING_BOX_VERSION"
  SB_VERSION=$SING_BOX_VERSION
  SB_NAME="sing-box-${SB_VERSION}-linux-${ARCH}.tar.gz"
  SB_URL="https://github.com/SagerNet/sing-box/releases/download/v${SB_VERSION}/${SB_NAME}"
  case "$ARCH" in
    amd64) SB_DIGEST="a684484d7477d1437282ee411f4d131d0340aaad60a7868841ebd5d87dd8a0c6" ;;
    arm64) SB_DIGEST="b43a1fb1bda131c6653576741ce527eb2bdeab7c9308ca90ee8b972abb7e4a7f" ;;
  esac
  curl -fL --retry 3 -o "$TMP_DIR/$SB_NAME" "$(github_url "$SB_URL")"
  printf '%s  %s\n' "$SB_DIGEST" "$TMP_DIR/$SB_NAME" | sha256sum -c -
  mkdir -p "$TMP_DIR/sing-box"
  tar --warning=no-unknown-keyword -xzf "$TMP_DIR/$SB_NAME" -C "$TMP_DIR/sing-box"
  SB_BIN=$(find "$TMP_DIR/sing-box" -type f -name sing-box | head -n 1)
  [ -n "$SB_BIN" ] || fail "Sing-box 安装包中未找到程序文件"
  install -m 0755 "$SB_BIN" /usr/local/bin/sing-box
  sing_box_compatible /usr/local/bin/sing-box || fail "安装后的 Sing-box 版本低于 1.14.0"
}

if [ "${SINGDECK_VERSION:-latest}" = "latest" ]; then
  VERSION=$LATEST_SINGDECK_VERSION
else
  VERSION=$(printf '%s' "$SINGDECK_VERSION" | tr -d '[:space:]')
fi

case "$VERSION" in
  v[0-9]*) ;;
  [0-9]*) VERSION="v$VERSION" ;;
  *) fail "无法识别版本号：${VERSION:-空值}（示例：v0.3.6）" ;;
esac

ASSET="singdeck-${VERSION}-linux-${ARCH}.tar.gz"
BASE_URL="https://github.com/$REPO/releases/download/$VERSION"

printf '正在下载 SingDeck %s (%s)…\n' "$VERSION" "$ARCH"
curl -fL --retry 3 -o "$TMP_DIR/$ASSET" "$(github_url "$BASE_URL/$ASSET")"
curl -fL --retry 3 -o "$TMP_DIR/$ASSET.sha256" "$(github_url "$BASE_URL/$ASSET.sha256")"
(cd "$TMP_DIR" && sha256sum -c "$ASSET.sha256")

mkdir -p "$TMP_DIR/singdeck"
tar --warning=no-unknown-keyword -xzf "$TMP_DIR/$ASSET" -C "$TMP_DIR/singdeck"
[ -x "$TMP_DIR/singdeck/singdeck" ] || fail "安装包内容不完整"

install_sing_box

if systemctl is-active --quiet singdeck.service 2>/dev/null; then
  systemctl stop singdeck.service
fi

install -d -m 0750 /etc/singdeck /etc/sing-box /var/lib/singdeck /var/lib/sing-box
install -m 0755 "$TMP_DIR/singdeck/singdeck" /usr/local/bin/singdeck
cat > /etc/sysctl.d/99-singdeck.conf <<'EOF'
# Required by SingDeck's TProxy policy routing.
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

apply_singdeck_sysctl() {
  SINGDECK_SYSCTL_KEY=$1
  SINGDECK_SYSCTL_VALUE=$(sysctl -n "$SINGDECK_SYSCTL_KEY" 2>/dev/null || true)
  if [ "$SINGDECK_SYSCTL_VALUE" = "1" ]; then
    return
  fi
  if ! sysctl -w "$SINGDECK_SYSCTL_KEY=1" >/dev/null 2>&1; then
    printf '提示：LXC 不允许修改 %s，请在 PVE 宿主机确认该容器允许网络转发。\n' "$SINGDECK_SYSCTL_KEY" >&2
  fi
}

apply_singdeck_sysctl net.ipv4.ip_forward
apply_singdeck_sysctl net.ipv6.conf.all.forwarding

if [ ! -f /etc/singdeck/singdeck.env ]; then
  PASSWORD=$(od -An -N18 -tx1 /dev/urandom | tr -d ' \n')
  umask 077
  printf 'SINGDECK_ADMIN_PASSWORD=%s\n' "$PASSWORD" > /etc/singdeck/singdeck.env
fi
if [ -n "$GITHUB_PROXY" ]; then
  sed -i '/^SINGDECK_GITHUB_PROXY=/d' /etc/singdeck/singdeck.env
  printf 'SINGDECK_GITHUB_PROXY=%s\n' "$GITHUB_PROXY" >> /etc/singdeck/singdeck.env
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
ExecStartPre=/usr/local/bin/singdeck --restore-network --data-dir /var/lib/singdeck --sing-box /usr/local/bin/sing-box --config /etc/sing-box/config.json
ExecStart=/usr/local/bin/singdeck --listen 0.0.0.0:8080 --data-dir /var/lib/singdeck --sing-box /usr/local/bin/sing-box --config /etc/sing-box/config.json
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/singdeck /etc/sing-box /usr/local/bin/sing-box
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/sing-box.service <<'EOF'
[Unit]
Description=sing-box Service managed by SingDeck
After=network-online.target singdeck.service
Wants=network-online.target singdeck.service

[Service]
Type=simple
ExecStart=/usr/local/bin/sing-box run -D /var/lib/sing-box -C /etc/sing-box
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sing-box.service
systemctl enable --now singdeck.service

HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -n "$HOST_IP" ] || HOST_IP="服务器IP"

printf '\nSingDeck %s 安装完成。\n' "$VERSION"
printf '访问地址：http://%s:8080\n' "$HOST_IP"
printf '用户名：admin\n'
printf '初始密码：%s\n' "$(sed -n 's/^SINGDECK_ADMIN_PASSWORD=//p' /etc/singdeck/singdeck.env)"
printf '请妥善保存密码，并优先通过可信内网或 HTTPS 访问。\n'
