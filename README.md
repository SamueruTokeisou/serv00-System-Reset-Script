

````md
# serv00 System Reset Script | serv00 系统重置脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ShellCheck](https://github.com/SamueruTokeisou/serv00/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/SamueruTokeisou/serv00/actions/workflows/shellcheck.yml)
[![Release](https://img.shields.io/github/v/release/SamueruTokeisou/serv00)](https://github.com/SamueruTokeisou/serv00/releases)

---

## Contents | 目录

- [Quick Start | 快速启动](#quick-start--快速启动)  
- [Overview | 简介](#overview--简介)  
- [Features | 功能特性](#features--功能特性)  
- [Installation | 安装说明](#installation--安装说明)  
- [Caution | 注意事项](#caution--注意事项)  
- [Contributing | 贡献](#contributing--贡献)  
- [License | 许可证](#license--许可证)  

---

## Quick Start | 快速启动

> Run immediately via:

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
````

> 立即运行：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```

---

## Overview | 简介

**serv00** is a lightweight system reset script designed for quick, safe server initialization over SSH.
It includes essential cleanup operations with safeguards to prevent accidental data loss.

**serv00** 是一款轻量级系统重置脚本，专为通过 SSH 快速且安全地初始化服务器设计。
集成了基础清理操作，并内置多重确认防止误删。

---

## Features | 功能特性

* Simple CLI with color-coded output 彩色命令行界面
* Multiple confirmations before destructive actions 多重操作确认
* Option to preserve user configuration 可选择保留用户配置
* Cleanup tasks include: 清理内容涵盖：

  * Removing cron jobs 清空计划任务
  * Terminating user processes 强制结束用户进程
  * Cleaning user home directories 清理用户主目录

---

## Installation | 安装说明

Move the script to system path for easy access:

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

Or add alias:

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

将脚本移动到系统路径方便调用：

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

或者设置别名：

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## Caution | 注意事项

⚠️ This script will irreversibly delete user data. Backup important files before use.

⚠️ 本脚本会不可逆删除用户数据，使用前请务必备份重要文件。

---

## Contributing | 贡献

Contributions and bug reports are welcome. Please follow the contributing guidelines.

欢迎贡献代码和报告问题，请遵守贡献规范。

---

## License | 许可证

MIT License © 2025 Samueru Tokeisou

MIT 许可证 © 2025 Tokeisou Samueru

---

```


```
