# SingDeck · 星舵

> 面向 Debian / PVE LXC 的 Sing-box Web 控制台，让节点、规则、DNS 与多设备配置在同一处管理。

本仓库是 SingDeck 的**公开发行仓库**，只提供产品介绍、安装维护脚本和经过校验的 AMD64 / ARM64 安装包，不包含 Go、React 或后端业务源代码。

## 功能概览

- 订阅、节点与节点筛选组管理
- 可编辑、可排序的规则策略和远程规则集
- DNS 分流、FakeIP 和实时查询监控
- Mixed、TProxy、Clash API 与系统服务管理
- 自动、亮色、暗色主题和移动端适配
- 生成其他设备使用的配置链接和二维码
- Sing-box 核心版本检查、配置校验与日志查看

## 支持范围

| 项目 | 当前支持 |
| --- | --- |
| 系统 | Debian / PVE LXC |
| 架构 | AMD64、ARM64 |
| 服务管理 | systemd |
| Docker / OpenWrt | 暂不支持 |

## 一键安装

SSH 登录 Debian / PVE LXC 后执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/install.sh | sudo sh
```

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

## 安装指定版本

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/install.sh \
  | sudo SINGDECK_VERSION=v0.3.1 sh
```

## 更新

重新执行安装命令即可保留数据库和密码并更新程序：

```bash
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/main/scripts/update.sh | sudo sh
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

## 关于源码

SingDeck 当前为私有闭源项目。公开仓库不包含历史源代码、构建配置或开发分支；发布安装包由独立的私有源码仓库构建。

Copyright © 2026 Ladavian. 个人、非商业用途可免费下载和使用，具体条款见 [LICENSE](LICENSE)。

SingDeck 与 SagerNet、sing-box 项目无隶属关系。Sing-box 由安装脚本从其官方 GitHub Release 获取，并遵循上游项目自己的许可证。
