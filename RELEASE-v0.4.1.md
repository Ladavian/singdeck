# SingDeck v0.4.1

适用于 Debian / PVE LXC，提供 Linux AMD64、ARM64 安装包。应用源码保持私有。

## 本次更新

- 完善旁路由 TUN / TProxy 设置、DNS 劫持、FakeIP、端口分流及故障恢复。
- 改进规则集自定义添加、内容详情、策略排序与兜底策略。
- 优化代理、连接、设置和移动端布局，加入品牌 PWA 图标及默认背景。
- 设备分享配置内嵌已校验的规则集，减少客户端首次启动对远程规则下载的依赖。
- 修复订阅下载开关读取旧配置的问题：保存后立即生效，无需重启核心；节点站点分流仍需应用配置。
- 安装器同步核心启动限速，避免失败后频繁重试。

## 安装 / 更新

已有安装重新执行以下命令会保留数据库、账号和配置：

```sh
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/v0.4.1/scripts/install.sh | sudo sh
```

无法直接连接 GitHub 时可使用第三方代理（安装包仍校验 SHA256）：

```sh
curl -fsSL "https://gh-proxy.com/https://raw.githubusercontent.com/Ladavian/singdeck/v0.4.1/scripts/install.sh" \
  | sudo GITHUB_PROXY=https://gh-proxy.com sh
```

安装包和对应 `.sha256` 文件均位于本页附件。更新管理程序不等于自动应用待保存的网络配置。

## 已知问题

本次已修复订阅下载偏好未即时生效的问题，但个别订阅返回 HTTP 502 的访问路径差异仍待排查，不代表该问题已完全解决。选择代理下载时必须有可用的核心代理入口。
