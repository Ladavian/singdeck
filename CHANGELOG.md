# 更新记录

## v0.3.6

- 改用 sing-box 1.14 官方 API 与官方 Dashboard，9090 直接展示规则组、连接和实时流量
- 移除已经停止支持 sing-box 的 Zashboard 依赖，并自动迁移旧默认设置
- 修复 `255.255.255.255` 广播流量误入 TProxy 引发的连接堆积和内存峰值
- 设备分享配置不再暴露管理 API 服务

## v0.3.5

- 修复 Sing-box 1.14.2 运行时拒绝直连 DNS 绕到空 `direct` 出站的问题
- 直连 DNS 改用 Sing-box 1.14 原生直连拨号，代理 DNS 仍通过 `Proxy` 选择器
- 在真实 52 节点配置上验证核心持续运行、TProxy、Mixed、DNS 与 Clash API 端口正常监听

## v0.3.4

- 修复新版 nftables 将 `tproxy` 识别为保留关键字、导致首次应用配置失败的问题
- 将 nftables 基础链改为兼容的多行语法，并在 Debian / PVE LXC 实机完成校验
- 核心启动或重启前检查配置文件；尚未应用配置时给出明确操作提示

## v0.3.3

- 新增 Clash YAML / JSON 订阅解析，覆盖 SS、Trojan、VLESS、VMess、Hysteria2 与 TUIC
- 新增 SingDeck 软件在线更新，与 Sing-box 核心更新统一到“系统 → 在线更新”
- 更新包下载后校验 SHA256，程序替换失败或重启失败时自动恢复上一版本
- GitHub 代理安装会保存代理配置，供后续网页在线更新继续使用
- 修复暗色主题登录页白色背景、自动填充白底和主题切换颜色不一致的问题

## v0.3.2

- 统一新版前后端，避免开发界面误连旧版接口
- 适配 Sing-box 1.14+ 的 HTTP Client 与远程规则集结构
- 增加节点启停、核心安装回滚和网络规则开机恢复
- 完善国内 IPv4/IPv6 绕过、DNS 分流与设备配置生成
- 更新安装器的 nftables、iproute2、systemd 权限和核心版本检查
- 增加管理员用户名/密码修改、PBKDF2-SHA256 密码保护和全会话注销
- 增加私有源码仓库的 GitHub 自动测试与 AMD64/ARM64 编译

## v0.3.1

- 首个 SingDeck 私有发行版本
- 支持 Debian / PVE LXC 的 AMD64 与 ARM64
- 完成订阅、节点、筛选组、规则策略和 DNS 管理
- 增加多设备配置链接、二维码与撤销管理
- 增加自动/亮色/暗色主题和响应式界面
- 增加 Sing-box 核心检查、配置应用、日志与服务控制
