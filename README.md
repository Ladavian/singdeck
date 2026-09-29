# SingDeck · 星舵

> 面向 Debian / PVE LXC 的 Sing-box Web 控制台，让节点、规则、DNS 与多设备配置在同一处管理。

本仓库是 SingDeck 的**公开发行仓库**，只提供产品介绍、安装维护脚本和经过校验的 AMD64 / ARM64 安装包，不包含 Go、React 或后端业务源代码。

## 功能概览

- 订阅、节点与节点筛选组管理，支持 Sing-box JSON、Clash YAML/JSON 和常见协议链接
- 可编辑、可排序的规则策略和远程规则集
- DNS 分流、FakeIP 和实时查询监控
- Mixed、TProxy、sing-box 1.14 官方 API / Dashboard 与系统服务管理
- 自动、亮色、暗色主题和移动端适配
- 生成其他设备使用的配置链接和二维码
- SingDeck 软件与 Sing-box 核心在线检查、校验安装、失败恢复和服务重启
- 管理员用户名和密码修改、全会话退出和加盐密码保护

## 支持范围

| 项目 | 当前支持 |
| --- | --- |
| 系统 | Debian / PVE LXC |
| 架构 | AMD64、ARM64 |
| 服务管理 | systemd |
| Docker / OpenWrt | 暂不支持 |

## 一键安装

SSH 登录 Debian / PVE LXC 后执行：

### GitHub 直连

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/install.sh | sudo sh
```

### 国内网络（GitHub 代理）

无法直接访问 GitHub 时，可以使用下面的代理安装命令：

```bash
curl -fsSL "https://gh-proxy.com/https://raw.githubusercontent.com/Ladavian/singdeck/d4ead50e7f7da1d249455fa4d50268530699bac1/scripts/install.sh" \
  | sudo GITHUB_PROXY=https://gh-proxy.com sh
```

代理命令固定到当前版本对应的安装器提交，避免公共代理缓存旧的 `main` 分支脚本。`GITHUB_PROXY` 会同时代理 SingDeck Release 和 Sing-box Release；安装包下载后仍会执行 SHA256 完整性校验。

> `gh-proxy.com` 是第三方公共代理，并非 GitHub、SingDeck 或 SagerNet 官方服务。代理不可用时可更换为兼容“代理前缀 + 完整 GitHub URL”格式的服务；涉及敏感环境时建议使用 GitHub 直连或自建代理。

安装脚本会：

1. 自动识别 AMD64 或 ARM64；
2. 从本仓库最新 [Release](https://github.com/Ladavian/singdeck/releases/latest) 下载对应 SingDeck 安装包；
3. 校验安装包 SHA256；
4. 如果系统没有 Sing-box，从 SagerNet 官方 Release 下载并校验后安装；
5. 创建 systemd 服务和随机管理密码；
6. 在终端显示访问地址、账号和初始密码。

默认访问地址：

```text
http://服务器IP:8080
```

管理员用户名为 `admin`，初始密码由安装器随机生成。

首次登录后请在“系统 → 账号安全”中修改用户名和密码；保存后所有旧的管理会话都会自动退出。

## 安装指定版本

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/install.sh \
  | sudo SINGDECK_VERSION=v0.3.7 sh
```

## 更新

v0.3.3 起可以在“系统 → 在线更新”中分别更新 SingDeck 软件和 Sing-box 核心。第一次从旧版本升级到 v0.3.3 时，重新执行安装命令即可保留数据库、密码和现有配置：

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/update.sh | sudo sh
```

通过 GitHub 代理安装时，安装器会保存代理地址，后续在网页中检查和下载 SingDeck / Sing-box 更新时会继续使用它。

无法直连 GitHub 时：

```bash
curl -fsSL "https://gh-proxy.com/https://raw.githubusercontent.com/Ladavian/singdeck/d4ead50e7f7da1d249455fa4d50268530699bac1/scripts/install.sh" \
  | sudo GITHUB_PROXY=https://gh-proxy.com sh
```

## 卸载

卸载程序但保留数据库和设置：

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/uninstall.sh | sudo sh
```

连同 SingDeck 数据一起删除：

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/uninstall.sh | sudo sh -s -- --purge
```

卸载器不会删除 Sing-box 核心和 `/etc/sing-box`，避免影响其他用途。

## 常用维护

```bash
systemctl status singdeck
systemctl restart singdeck
journalctl -u singdeck -n 200 --no-pager
```

重要目录：

```text
/usr/local/bin/singdeck          SingDeck 程序
/etc/singdeck/singdeck.env      管理密码与环境参数
/var/lib/singdeck/               数据库和运行数据
/usr/local/bin/sing-box          Sing-box 核心
/etc/sing-box/config.json        生成的 Sing-box 配置
```

## 安全说明

- 建议只在可信内网访问，或通过 HTTPS 反向代理并限制来源 IP。
- 设备配置链接拥有读取完整节点配置的能力，不用时请立即撤销。
- 请勿公开 `/etc/singdeck/singdeck.env`、数据库、订阅地址和分享链接。
- 每个 Release 资产都提供独立 SHA256 文件，安装器校验通过后才会替换程序。
- 安装器要求 Sing-box 1.14.0 或更高版本；旧核心会自动更新到官方稳定版。

## 关于源码

Copyright © 2026 Ladavian. 个人、非商业用途可免费下载和使用，具体条款见 [LICENSE](LICENSE)。

SingDeck 与 SagerNet、sing-box 项目无隶属关系。Sing-box 由安装脚本从其官方 GitHub Release 获取，并遵循上游项目自己的许可证。
