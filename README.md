

# 🔄 Serv00 系统恢复脚本

<div align="center">

![Version](https://img.shields.io/badge/版本-1.0-FF6B6B?style=flat-square&logo=rocket)
![Serv00](https://img.shields.io/badge/Serv00-专属优化-00DDEB?style=flat-square&logo=server)
![License](https://img.shields.io/badge/许可证-MIT-1E90FF?style=flat-square)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash)

**专注核心功能，安全可靠的 Serv00 系统恢复工具**

[快速开始](#-快速开始) • [功能说明](#-功能说明) • [使用指南](#-使用指南) • [常见问题](#-常见问题)

</div>

---

## 📖 简介

**Serv00 系统恢复脚本** 是一个专为 Serv00 VPS 设计的轻量级系统重置工具。它只做一件事，并把它做到最好：**安全、完整地恢复系统到初始状态**。

### 为什么选择这个脚本？

- ✅ **功能专注**：只提供系统恢复功能，避免功能臃肿
- ✅ **安全可靠**：智能保护 SSH 连接和脚本进程，不会中途中断
- ✅ **配置灵活**：可选择保留用户配置文件，避免重复设置
- ✅ **零依赖**：纯 Bash 实现，无需安装额外工具
- ✅ **开箱即用**：下载即可运行，一键完成系统恢复

---

## ⚡ 快速开始



## ⚡ 快速启动

### 稳定版本
经典版本，简洁高效：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```

### Beta 版本
一键体验最新功能：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script-beta.sh
chmod +x system-cleanup-script-beta.sh
./system-cleanup-script-beta.sh
```
---

---

## 🎯 功能说明

### 核心功能

本脚本提供 **3 个精简功能**，专注于系统恢复：

| 功能 | 说明 | 适用场景 |
|------|------|----------|
| 🔄 **系统恢复** | 完整清理 Cron + 进程 + 文件 | 系统污染、全新部署、重新开始 |
| ⏰ **清理 Cron** | 仅清空所有定时任务 | 快速清理定时任务，不影响其他 |
| 🚪 **退出脚本** | 安全退出 | 取消操作 |

### 清理范围

#### 保留配置模式（默认推荐）

✅ **会清理**：
- 所有非隐藏文件和目录（`~/文件名`）
- 常见缓存目录（`.cache`、`.local`、`.npm`、`.pip` 等）
- 开发环境目录（`go`、`node_modules` 等）
- 所有 Cron 定时任务
- 所有用户后台进程

❌ **会保留**：
- `.ssh/`（SSH 密钥和配置）
- `.bashrc`（Bash 配置）
- `.profile`（用户环境变量）
- `.bash_profile`（登录配置）
- `.bash_logout`（登出配置）

#### 完全清理模式

✅ **会清理**：保留配置模式的所有项 + 所有隐藏配置文件

❌ **仅保留**：
- `.ssh/`（SSH 密钥，避免无法登录）
- 基础 Shell 配置文件（`.bashrc`、`.profile` 等）

---

## 📖 使用指南

### 主菜单

启动脚本后会看到：

```
=========================================
    Serv00 系统恢复脚本 v1.0
=========================================
请选择操作：

  1) 恢复系统（清理 Cron + 进程 + 文件）
  2) 仅清理 Cron 任务
  3) 退出

=========================================
请输入选项 [1-3]:
```

### 操作流程

#### 1️⃣ 恢复系统

**步骤 1：确认操作**
```
⚠️  警告：此操作将执行以下清理 ⚠️
  • 删除所有 Cron 定时任务
  • 终止所有用户后台进程
  • 清空磁盘文件（可选保留配置）

是否继续？[y/N]:
```

**步骤 2：选择模式**
```
是否保留配置文件（.bashrc/.profile/.ssh 等）？[Y/n]:
```

**步骤 3：执行清理**
```
=========================================
开始执行系统恢复...
=========================================
✓ 已清空所有 Cron 任务

正在清理用户进程...
✓ 已终止非关键用户进程

正在清理磁盘文件...
✓ 已清理可见文件和缓存（保留隐藏配置）

=========================================
✅ 系统恢复完成！
=========================================
提示：已保留 SSH 配置和 shell 配置文件
```

#### 2️⃣ 仅清理 Cron

快速清空所有 Cron 定时任务，不影响进程和文件：

```
=========================================
    Serv00 系统恢复脚本 v1.0
=========================================
✓ 已清空所有 Cron 任务

按 Enter 返回菜单...
```

---

## 🛡️ 安全机制

### 智能进程保护

脚本在清理用户进程时会自动排除：
- ✅ 脚本自身进程（避免自杀）
- ✅ 脚本父进程（保护调用环境）
- ✅ init 进程（PID 1）

**技术实现**：
```bash
# 获取所有用户进程，排除关键进程
local pids=$(ps -u "$user" -o pid= | grep -v -E "^($script_pid|$parent_pid|1)$")
```

### SSH 连接说明

⚠️ **重要提示**：清理用户进程时，SSH 连接可能会被终止（这是正常现象）

**原因**：SSH 连接本身也是用户进程，无法在清理时完全排除

**解决方案**：
1. 等待 3-5 秒后重新连接
2. 系统已恢复，可以正常使用
3. 如果保留了配置，SSH 密钥和设置不变

### 配置文件保护

脚本使用 **白名单机制** 保护关键配置：

```bash
# 保护列表
protected=(".ssh" ".bashrc" ".profile" ".bash_profile" ".bash_logout")
```

只有这些文件/目录在完全清理模式下也会被保留，确保系统可用性。

---

## 💡 使用场景

### 适合使用的情况

✅ **系统环境污染**
- 安装了大量不需要的软件包
- 配置文件混乱，难以清理

✅ **重新开始项目**
- 需要全新的开发环境
- 切换不同技术栈

✅ **定时任务失控**
- Cron 任务过多且难以管理
- 需要快速清空所有定时任务

✅ **进程占用异常**
- 后台进程卡死或占用资源
- 需要批量终止用户进程

### 不适合使用的情况

❌ **有重要数据未备份**
- 脚本会永久删除文件，操作不可逆

❌ **不确定系统状态**
- 建议先查看磁盘使用情况
- 确认无重要数据后再操作

❌ **多人共用账户**
- 会影响其他用户的进程和文件

---

## ❓ 常见问题

### Q1: 脚本会删除哪些文件？

**A:** 默认保留配置模式下：
- 删除所有 **非隐藏文件**（如 `~/test.txt`）
- 删除 **缓存目录**（如 `.cache`、`.npm`）
- 保留 **关键配置**（如 `.ssh`、`.bashrc`）

完全清理模式下会删除更多，但仍保留 SSH 和基础 Shell 配置。

### Q2: 清理进程会断开 SSH 吗？

**A:** 可能会。SSH 连接是用户进程，清理时可能被终止。这是正常现象，等待几秒后可重新连接。

### Q3: 如何恢复删除的文件？

**A:** Serv00 提供 7 天自动备份，可以通过管理面板恢复。建议清理前手动备份重要数据。

### Q4: 脚本支持其他 VPS 吗？

**A:** 理论上支持所有 Linux/FreeBSD 系统，但针对 Serv00 优化。其他环境请先测试。

### Q5: 为什么没有更多功能？

**A:** 本脚本遵循 **单一职责原则**，只专注系统恢复。功能精简意味着：
- 更少的 bug
- 更高的可靠性
- 更容易维护
- 更快的执行速度

### Q6: 可以在生产环境使用吗？

**A:** 可以，但请务必：
1. 先在测试环境验证
2. 备份所有重要数据
3. 了解清理范围和影响
4. 在维护窗口执行

---

## 🔧 安装与配置

### 永久安装

将脚本安装到系统路径，方便随时调用：

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/YourUsername/serv00-reset/main/reset.sh

# 移动到系统目录（如果有权限）
sudo mv reset.sh /usr/local/bin/serv00-reset

# 添加执行权限
sudo chmod +x /usr/local/bin/serv00-reset
```

现在可以直接运行：
```bash
serv00-reset
```

### 别名配置

如果没有 root 权限，可以使用别名：

```bash
# Bash 用户
echo "alias serv00-reset='bash ~/reset.sh'" >> ~/.bashrc
source ~/.bashrc

# Zsh 用户
echo "alias serv00-reset='bash ~/reset.sh'" >> ~/.zshrc
source ~/.zshrc
```

---

## ⚠️ 注意事项

### 使用前必读

1. **数据安全**
   - ⚠️ 清理操作 **不可逆**，请务必备份重要数据
   - ⚠️ Serv00 虽有自动备份，但不能完全依赖

2. **系统影响**
   - ⚠️ 会清空所有 Cron 定时任务
   - ⚠️ 会终止所有用户进程（包括后台服务）
   - ⚠️ 会删除大部分文件（根据选择的模式）

3. **SSH 连接**
   - ⚠️ 清理进程时 SSH 可能断开（正常现象）
   - ✅ 等待几秒后可重新连接
   - ✅ 保留配置模式下 SSH 密钥不变

4. **最佳实践**
   - 📝 清理前备份重要数据
   - 🧪 首次使用建议在测试账户验证
   - 📋 记录重要的环境变量和配置
   - ⏰ 选择合适的维护时间窗口

---

## 🤝 贡献

欢迎参与改进！

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/improvement`)
3. 提交更改 (`git commit -m 'Add improvement'`)
4. 推送到分支 (`git push origin feature/improvement`)
5. 提交 Pull Request

### 反馈渠道

- 🐛 [提交 Issue](https://github.com/YourUsername/serv00-reset/issues)
- 💬 [讨论区](https://github.com/YourUsername/serv00-reset/discussions)
- 📧 Email: your-email@example.com

---

## 📜 更新日志

### v1.0 (2025-11-22)

**首次发布**
- ✨ 系统恢复核心功能
- ✨ Cron 任务清理
- ✨ 智能进程保护机制
- ✨ 配置文件保留选项
- 🎨 简洁友好的用户界面
- 🛡️ 完善的错误处理
- 📖 详细的使用文档

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- 感谢 [Serv00](https://serv00.com) 提供的免费 VPS 服务
- 感谢所有使用和反馈的用户
- 感谢开源社区的支持

---

<div align="center">

### 🌟 觉得有用？给个 Star 吧！

**专注核心，安全可靠 · 为 Serv00 用户量身打造**

</div>

---

<div align="center">
  <sub>Made with ❤️ for Serv00 Community</sub>
</div>

---

<footer align="center">
  <sub>© 2025 Tokeisou Samueru · 系统重置，征服虚空 · 代码精简，效率至上</sub>
  <br>
  <sub>🚀 Made with ❤️ for Serv00 Community</sub>
</footer>
