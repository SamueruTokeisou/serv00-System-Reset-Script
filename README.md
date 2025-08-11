# serv00

A lightweight system reset script for quick and safe SSH server initialization.


一个用于快速安全地初始化SSH服务器的轻量级系统重置脚本。

---

## Overview | 简介

**serv00** is a lightweight system reset script designed for quick, safe server initialization over SSH. It includes essential cleanup tasks with safeguards to prevent accidental data loss.

**serv00** 是一款轻量级系统重置脚本,专为通过 SSH 快速且安全地初始化服务器设计。它集成了基础清理任务,并内置多重确认机制以防止误删。

---


## Quick Start | 快速启动

> Run immediately via:  
> 立即运行：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```
---
## Overview | 简介

**serv00** is designed to safely and swiftly reset your server via SSH.
It automates essential cleanup tasks with built-in safeguards to prevent accidental data loss.

**serv00** 专为通过 SSH 快速且安全地重置服务器而设计，
自动执行关键清理操作，并内置多重确认防止误删数据。

---

## Features | 功能特性

* Simple and intuitive CLI with color-coded output
  简洁直观的彩色命令行界面
* Multiple confirmation prompts before executing destructive actions
  多重确认提示，避免误操作
* Option to preserve user configurations selectively
  可选择保留用户配置
* Cleanup tasks include:
  清理任务涵盖：

  * Removing cron jobs
    清空计划任务
  * Terminating user processes
    强制结束用户进程
  * Cleaning user home directories
    清理用户主目录

---

## Installation | 安装说明

For easier access, move the script to your system PATH:

方便调用，将脚本移动到系统路径：

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

Alternatively, add an alias:

或者设置别名：

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## Caution | 注意事项

⚠️ This script irreversibly deletes user data. Please backup important files before use.


⚠️ 本脚本会不可逆删除用户数据，使用前请务必备份重要文件。

---
