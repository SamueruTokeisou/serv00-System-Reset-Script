# serv00 系统重置脚本 | serv00 System Reset Script

[中文](#中文) | [English](#english)
---

## 中文

### 概述

**serv00** 是一个简洁的系统重置脚本，旨在通过 SSH 轻松初始化服务器。它提供了基本的清理和系统重置功能，并内置了防止意外数据丢失的安全措施。

### 主要特性

- 简单的 SSH 界面
- 彩色输出，提高可读性
- 操作确认提示，防止误操作
- 可选择保留用户配置
- 全面的清理任务：
  - 清除 cron 任务
  - 终止用户进程
  - 清理用户主目录

### 手动安装

1. 下载脚本：
   ```bash
   curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
   ```
2. 添加执行权限：
   ```bash
   chmod +x system-cleanup-script.sh
   ```
3. 运行脚本：
   ```bash
   ./system-cleanup-script.sh
   ```

### 高级设置

为方便访问：

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

或创建别名：

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```
### 注意事项

此脚本会删除用户数据。使用前请务必备份重要信息。
---

## English

### Overview

**serv00** is a streamlined system reset script designed for easy server initialization via SSH. It offers essential cleanup and system reset functionalities with built-in safeguards against accidental data loss.

### Key Features

- Simple SSH-based interface
- Color-coded output for enhanced readability
- Confirmation prompts to prevent unintended actions
- Option to preserve user configurations
- Comprehensive cleanup tasks:
  - Cron job clearance
  - User process termination
  - Home directory cleanup

### Manual Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
   ```
2. Make it executable:
   ```bash
   chmod +x system-cleanup-script.sh
   ```
3. Run the script:
   ```bash
   ./system-cleanup-script.sh
   ```

### Advanced Setup

For easier access:

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

Or create an alias:

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

### Caution

This script deletes user data. Always backup important information before use.




