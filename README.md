# 🚀 Serv00 系统重置脚本 - 精简增强版
轻量级、智能化、高性能脚本，专为 Serv00 环境打造的系统重置解决方案

<div align="center" style="margin-bottom: 24px;">
  <img src="https://img.shields.io/badge/版本-2.0_Beta-FF6B6B?style=flat-square&logo=rocket" alt="Version 2.0 Beta" />
  <img src="https://img.shields.io/badge/Serv00-优化适配-00DDEB?style=flat-square&logo=server" alt="Serv00 优化" />
  <img src="https://img.shields.io/badge/许可证-MIT-1E90FF?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/badge/平台-Linux/FreeBSD-D91414?style=flat-square&logo=linux" alt="Platform" />
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash" alt="Bash" />
</div>

<div align="center" style="margin-bottom: 24px;">
  📖 <a href="README-en.md">English</a> | 🌐 <a href="https://www.samueru.nyc.mn">Typecho 博客</a> | 📝 <a href="https://memos.286163668.xyz">Memos 笔记</a> | 📡 <a href="https://x.com/SamueruTokeisou">X</a>
</div>

---

## 📋 目录

- [简介](#-简介)
- [新特性](#-新特性-v20-beta)
- [快速启动](#-快速启动)
- [功能特性](#-功能特性)
- [使用指南](#-使用指南)
- [技术亮点](#-技术亮点)
- [安装说明](#-安装说明)
- [常见问题](#-常见问题)
- [注意事项](#️-注意事项)
- [贡献](#-贡献)
- [更新日志](#-更新日志)

---

## 🌟 简介

**Serv00 系统重置脚本 - 精简增强版** 是一个专为 Serv00 VPS 环境设计的智能化系统重置工具。它在保持轻量高效的同时，融合了企业级的安全机制和用户友好的交互体验。

### 为什么选择增强版？

- ✅ **零备份设计**：充分利用 Serv00 自带的 7 天自动备份机制
- 备份文件目录:<image-card alt="Backup Directory" src="https://github.com/SamueruTokeisou/serv00-System-Reset-Script/blob/main/%E5%A4%87%E4%BB%BD%E7%9B%AE%E5%BD%95.png?raw=true" ></image-card>
- ✅ **进程自保护**：解决原版脚本"自杀"问题，确保清理完整执行
- ✅ **智能错误处理**：每个操作都有状态反馈和异常处理
- ✅ **模块化设计**：支持独立执行 cron 清理、进程管理等功能
- ✅ **美化界面**：彩色状态标识、进度条、倒计时提醒

---

## 🎉 新特性 (v2.0 Beta)

### 🛡️ 安全性升级
- **进程自保护机制**：清理用户进程时自动排除脚本自身
- **环境预检查**：启动前验证必要命令和系统环境
- **信号捕获处理**：优雅处理 Ctrl+C 等中断信号

### 🎨 用户体验优化
- **彩色进度指示**：`[1/4]`、`[2/4]` 等清晰的步骤展示
- **状态符号反馈**：✓（成功）、✗（失败）、⚠（警告）、→（进行中）
- **倒计时提醒**：危险操作前 3 秒倒计时警告
- **美化菜单界面**：蓝色边框装饰，专业美观

### ⚡ 功能增强
- **独立功能模块**：5 个独立操作选项，灵活调用
- **智能缓存清理**：自动清理 `.cache`、`.npm`、`.yarn` 等临时目录
- **环境信息查看**：实时查看磁盘、进程、文件统计
- **可选日志记录**：操作日志自动保存，便于追溯

---

## ⚡ 快速启动

### Beta 版本（推荐）
一键体验最新功能：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script-beta.sh
chmod +x system-cleanup-script-beta.sh
./system-cleanup-script-beta.sh
```

### 稳定版本
经典版本，简洁高效：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```

---

## 🔥 功能特性

### 核心功能

| 功能 | 描述 | 优势 |
|------|------|------|
| 🗑️ **系统初始化** | 完整清理系统环境 | 4 步流程，进度可视化 |
| ⏰ **Cron 清理** | 清空所有定时任务 | 独立调用，快速执行 |
| 🔄 **进程管理** | 终止用户所有进程 | 自保护机制，安全可靠 |
| 📊 **环境信息** | 查看系统状态 | 磁盘、进程、文件统计 |
| 📝 **操作日志** | 记录所有操作 | 便于审计和故障排查 |

### 清理范围

#### 标准清理模式（保留配置）
- ✅ 删除所有非隐藏文件和目录
- ✅ 清理临时缓存目录（`.cache`、`.npm`、`.yarn`）
- ✅ 清空所有 cron 定时任务
- ✅ 终止所有用户进程
- ❌ 保留用户配置文件（`.bashrc`、`.ssh`、`.profile`）

#### 完全清理模式
- ✅ 删除**所有**文件和目录（包括隐藏文件）
- ✅ 仅保留操作日志
- ⚠️ 谨慎使用，需要重新配置环境

### 智能保护

- 🛡️ **自动保护**：脚本运行时不会被自己终止
- 🔒 **日志保护**：清理过程中保留日志文件
- ⏱️ **倒计时警告**：危险操作前 3 秒倒计时
- 💾 **依赖 Serv00 备份**：无需额外备份，减少磁盘占用

---

## 📖 使用指南

### 主菜单功能

启动脚本后，你将看到：

```
╔════════════════════════════════════════════════════════╗
║          serv00 系统清理脚本 - SSH 管理面板           ║
║                     精简增强版 2.0                     ║
╚════════════════════════════════════════════════════════╝

  1. 初始化系统（清理数据）
  2. 仅清理 cron 任务
  3. 仅清理用户进程
  4. 查看环境信息
  5. 退出
```

### 选项说明

#### 1️⃣ 初始化系统
完整的系统重置流程：
- 清理 cron 定时任务
- 清理特殊目录（`~/go`、缓存等）
- 清理主目录文件
- 终止用户进程（可能断开 SSH）

**适用场景**：全新部署、环境污染、系统故障

#### 2️⃣ 仅清理 cron 任务
快速清空所有 crontab 定时任务。

**适用场景**：取消所有定时脚本、重新规划任务

#### 3️⃣ 仅清理用户进程
终止所有用户进程（SSH 连接可能断开）。

**适用场景**：进程卡死、资源占用异常

#### 4️⃣ 查看环境信息
实时显示：
- 用户名和主目录
- 磁盘使用情况
- Cron 任务数量
- 用户进程数量
- 文件/目录统计

**适用场景**：健康检查、清理前确认

---

## 💡 技术亮点

### 代码质量

```bash
# 进程自保护示例
kill_user_proc() {
    local user=$(whoami)
    # 排除当前脚本进程
    local processes=$(ps -u "$user" -o pid= | grep -v "^[[:space:]]*$SCRIPT_PID$")
    
    for pid in $processes; do
        kill -9 "$pid" 2>/dev/null
    done
}
```

### 安全机制

- ✅ 使用 `set -o pipefail` 捕获管道错误
- ✅ 使用 `mktemp` 创建临时文件
- ✅ 所有操作都有返回值检查
- ✅ 信号捕获优雅退出

### 性能优化

- ⚡ 无备份操作，执行速度快
- ⚡ 最小化磁盘 I/O
- ⚡ 模块化设计，按需执行

---

## 🔧 安装说明

### 永久安装（推荐）

将脚本安装到系统路径：

```bash
# 下载 Beta 版本
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script-beta.sh

# 移动到系统目录
sudo mv system-cleanup-script-beta.sh /usr/local/bin/serv00-reset

# 添加执行权限
sudo chmod +x /usr/local/bin/serv00-reset
```

现在你可以在任何位置运行：
```bash
serv00-reset
```

### 别名方式（轻量）

添加到 Shell 配置文件：

```bash
# Bash 用户
echo "alias serv00-reset='bash ~/system-cleanup-script-beta.sh'" >> ~/.bashrc
source ~/.bashrc

# Zsh 用户
echo "alias serv00-reset='bash ~/system-cleanup-script-beta.sh'" >> ~/.zshrc
source ~/.zshrc
```

---

## ❓ 常见问题

### Q1: 为什么没有备份功能？
**A:** Serv00 提供自动 7 天备份服务，无需脚本额外备份。这样设计更轻量、执行更快。

### Q2: 清理进程会断开 SSH 吗？
**A:** 是的，因为 SSH 连接也是用户进程。脚本会在清理前倒计时 3 秒警告，并在最后一步执行清理。

### Q3: 如何恢复删除的文件？
**A:** 联系 Serv00 管理面板，使用自动备份恢复功能。

### Q4: 脚本安全吗？
**A:** 是的。所有操作都在用户权限内，不涉及 root 权限。且代码开源可审计。

### Q5: Beta 版和稳定版有什么区别？
**A:** Beta 版包含最新功能（进程自保护、环境信息等），稳定版是经典简洁版本。推荐使用 Beta 版。

### Q6: 可以在其他 VPS 上使用吗？
**A:** 理论上可以，但专为 Serv00 优化。其他环境请谨慎测试。

---

## ⚠️ 注意事项

### 使用前必读

1. **数据安全**
   - ⚠️ 本脚本会**永久删除**大部分数据
   - ⚠️ 虽然 Serv00 有自动备份，但仍建议手动备份关键数据
   - ⚠️ 删除操作**不可逆**，请三思而后行

2. **SSH 连接**
   - ⚠️ 清理用户进程会**断开 SSH 连接**
   - ✅ 这是正常现象，等待几秒后可重新连接

3. **配置文件**
   - ✅ 标准模式会保留 `.bashrc`、`.ssh`、`.profile` 等配置
   - ⚠️ 完全清理模式会删除所有配置，需要重新设置

4. **最佳实践**
   - 📝 首次使用前，先选择「查看环境信息」了解系统状态
   - 🧪 在测试账户上先行测试
   - 📋 记录重要的配置信息

---

## 🤝 贡献

欢迎参与系统重置脚本的改进！

### 贡献方式

1. **Fork 本仓库**
2. **创建特性分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'Add some AmazingFeature'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **提交 Pull Request**

### 反馈渠道

- 🐛 [提交 Issue](https://github.com/SamueruTokeisou/serv00/issues)
- 💬 [X (Twitter)](https://x.com/SamueruTokeisou)
- 📧 通过博客联系我

### 贡献者名单

感谢所有贡献者！🎉

---

## 📜 更新日志

### v2.0 Beta (2025-10-25)

**新增功能**
- ✨ 进程自保护机制
- ✨ 环境信息查看功能
- ✨ 独立模块调用（cron、进程）
- ✨ 智能缓存清理

**优化改进**
- 🎨 美化用户界面
- 🛡️ 增强错误处理
- ⚡ 提升执行速度
- 📝 添加操作日志

**Bug 修复**
- 🐛 修复进程清理导致脚本中断的问题
- 🐛 修复 cron 清理失败的边界情况

### v1.0 (2024)

**初始版本**
- 🎉 基础系统清理功能
- 🎉 Cron 任务清理
- 🎉 用户进程管理

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- 感谢 [Serv00](https://serv00.com) 提供优质的免费 VPS 服务
- 感谢所有使用和反馈的用户
- 感谢开源社区的支持

---

<div align="center">

### 🌟 如果这个项目对你有帮助，请给一个 Star！

[![Star History Chart](https://api.star-history.com/svg?repos=SamueruTokeisou/serv00&type=Date)](https://star-history.com/#SamueruTokeisou/serv00&Date)

</div>

---

<footer align="center">
  <sub>© 2025 Tokeisou Samueru · 系统重置，征服虚空 · 代码精简，效率至上</sub>
  <br>
  <sub>🚀 Made with ❤️ for Serv00 Community</sub>
</footer>
