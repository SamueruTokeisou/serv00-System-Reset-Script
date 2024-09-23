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


一键创建go：

1. 打开终端，确保你在主目录或其他合适的目录中。
2. 使用以下命令创建脚本：

```bash
cat << 'EOF' > ~/upgrade_go.sh
#!/bin/bash

# 创建安装目录
mkdir -p ~/local/soft && cd ~/local/soft

# 下载编译好的 go1.22 的程序包
wget https://dl.google.com/go/go1.22.0.freebsd-amd64.tar.gz

# 解压
tar -xzvf go1.22.0.freebsd-amd64.tar.gz

# 删除压缩文件
rm go1.22.0.freebsd-amd64.tar.gz

# 修改 .profile 文件
echo 'export PATH=~/local/soft/go/bin:$PATH' >> ~/.profile

# 使 .profile 的修改生效
source ~/.profile

# 检查 go 版本
go version

echo "Go 语言环境升级完成！"
EOF
```

3. 赋予执行权限：

```bash
chmod +x ~/upgrade_go.sh
```

4. 运行脚本：

```bash
~/upgrade_go.sh
```

确保没有错误消息。如果一切顺利，你应该能看到 Go 语言环境被成功升级的消息。

