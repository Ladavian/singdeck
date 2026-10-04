# SingDeck v0.4.2

设备导入兼容性修复版，适用于 Debian / PVE LXC，提供 AMD64、ARM64 安装包。源码保持私有。

## 修复内容

- 配置二维码改用官方 `sing-box://import-remote-profile` 格式，支持官方客户端扫码导入；保留普通下载链接用于手动添加远程配置。
- 二维码弹窗增加“在 sing-box 中导入”入口。
- 设备配置跳过官方核心不支持的 SIP003 插件节点（例如 gost-plugin），重新生成节点组成员，不删除原始节点记录，也不移除插件参数伪装成可用节点。
- 全部启用节点或全部指定 Proxy 出口不兼容时，明确提示，避免静默切换为直连。
- 订阅网络错误提示隐藏完整订阅地址和令牌；代理入口未运行、下载超时分别给出说明。

## 更新

已有安装重新执行安装器会保留数据库、账号和配置：

```sh
curl -fsSL https://raw.githubusercontent.com/Ladavian/singdeck/v0.4.2/scripts/install.sh | sudo sh
```

GitHub 无法直连时，可使用第三方代理：

```sh
curl -fsSL "https://gh-proxy.com/https://raw.githubusercontent.com/Ladavian/singdeck/v0.4.2/scripts/install.sh" \
  | sudo GITHUB_PROXY=https://gh-proxy.com sh
```

更新后重新打开设备二维码；已导入的远程配置需要在客户端重新更新。

## 已知问题

订阅返回 HTTP 502 的访问路径问题仍待排查，本版不宣称已解决。二维码格式和插件兼容修复不等于所有订阅网络问题都已恢复。

附件包含两个架构的安装包及 SHA256 校验文件。
