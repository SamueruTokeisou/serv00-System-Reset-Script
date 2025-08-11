
````md
# serv00 System Reset Script | serv00 系统重置脚本

---

## 📚 Contents | 目录

- [Quick Start | 快速启动](#quick-start--快速启动)  
- [Overview | 简介](#overview--简介)  
- [Features | 功能特性](#features--功能特性)  
- [Installation | 安装说明](#installation--安装说明)  
- [Caution | 注意事项](#caution--注意事项)  
- [Contributing | 贡献](#contributing--贡献)  
- [License | 许可证](#license--许可证)  

---

<details>
<summary>English Version (click to expand)</summary>

### Quick Start

Run immediately:

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
````

### Overview

**serv00** is a lightweight system reset script designed for quick, safe server initialization over SSH.
It includes essential cleanup operations with safeguards to prevent accidental data loss.

### Features

* Simple CLI with color-coded output
* Multiple confirmations before destructive actions
* Option to preserve user configuration
* Cleanup tasks include:

  * Removing cron jobs
  * Terminating user processes
  * Cleaning user home directories

### Installation

Move the script to system path for easy access:

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

Or add alias:

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

### Caution

⚠️ This script will irreversibly delete user data. Backup important files before use.

### Contributing

Contributions and bug reports are welcome. Please follow the contributing guidelines.

### License

MIT License © 2025 Samueru Tokeisou

</details>

<details>
<summary>中文版 (点击展开)</summary>

### 快速启动

立即运行：

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```

### 简介

**serv00** 是一款轻量级系统重置脚本，专为通过 SSH 快速且安全地初始化服务器设计。
集成了基础清理操作，并内置多重确认防止误删。

### 功能特性

* 简洁的命令行界面，支持彩色输出
* 多重确认防止误删
* 支持选择性保留用户配置
* 清理内容涵盖：

  * 清空计划任务
  * 强制结束用户进程
  * 清理用户主目录

### 安装说明

将脚本移动到系统路径方便调用：

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

或者设置别名：

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

### 注意事项

⚠️ 本脚本会不可逆删除用户数据，使用前请务必备份重要文件。

### 贡献

欢迎贡献代码和报告问题，请遵守贡献规范。

### 许可证

MIT 许可证 © 2025 Tokeisou Samueru

</details>
```

——


你觉得怎么样？需要我帮你微调或者加点内容吗？
