# serv00 System Reset Script | serv00 系统重置脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ShellCheck](https://github.com/SamueruTokeisou/serv00/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/SamueruTokeisou/serv00/actions/workflows/shellcheck.yml)
[![Release](https://img.shields.io/github/v/release/SamueruTokeisou/serv00)](https://github.com/SamueruTokeisou/serv00/releases)

---

## Quick Start

> Run the script immediately with:

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
---

## Overview

`serv00` is a lightweight system reset tool designed for fast and safe server initialization over SSH.
It supports basic cleaning tasks with safeguards to prevent accidental data loss.

---

## Features

* Simple CLI interface with color-coded output
* Multiple confirmation steps before destructive actions
* Optionally preserve user configs
* Cleanup includes:

  * Cron job removal
  * Forced termination of user processes
  * User home directory cleanup

---

## Installation

Move the script to your system path for easier usage:

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

Or create a shell alias:

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## Caution

⚠️ This script irreversibly deletes user data. Please back up important files beforehand.

---

## Contributing

Contributions and bug reports are welcome. Please review the contributing guidelines before submitting.

---

## License

Distributed under the MIT License. See `LICENSE` for details.

---

# serv00 系统重置脚本

---

## 快速启动

> 立即运行脚本：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```

---

## 简介

`serv00` 是一个轻量级系统重置工具，专为 SSH 远程快速且安全初始化服务器设计。
支持基础清理任务，并配备多重确认机制防止误操作。

---

## 功能特性

* 简洁的命令行界面，支持彩色输出
* 多重确认防止误删
* 支持选择性保留用户配置
* 清理内容包括：

  * 清空计划任务（cron）
  * 强制终止用户进程
  * 清理用户主目录

---

## 安装说明

将脚本移动到系统路径，方便调用：

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

或设置别名：

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## 注意事项

⚠️ 本脚本会不可逆删除用户数据，请务必备份重要文件。

---

## 贡献指南

欢迎提交贡献和报告问题，提交前请先阅读贡献规范。

---

## 许可证

遵循 MIT 许可证，详见 `LICENSE` 文件。

```
