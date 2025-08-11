：

````md
<div align="center">

  <img src="https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/logo.svg" alt="serv00 Logo" width="128" height="128" />

  <p><em>serv00 - Lightweight system reset script for quick and safe SSH server initialization.</em></p>

</div>

---

# Quick Start | 快速启动

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

# Overview | 简介

**serv00** is a lightweight system reset script designed for quick, safe server initialization over SSH.
It includes essential cleanup tasks with safeguards to prevent accidental data loss.

**serv00** 是一款轻量级系统重置脚本，专为通过 SSH 快速且安全地初始化服务器设计。
集成了基础清理任务，并内置多重确认防止误删。

---

# Features | 功能特性

* Simple CLI with color-coded output
* Multiple confirmations before destructive actions
* Optionally preserve user configuration
* Cleanup tasks: remove cron jobs, terminate user processes, clean user home directories

---

# Installation | 安装说明

To use more conveniently, move the script to system path:

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

Or add alias:

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

方便调用的话，把脚本放到系统路径：

```bash
sudo mv system-cleanup-script.sh /usr/local/bin/serv00-reset
```

或者设置别名：

```bash
echo "alias serv00-reset='~/path/to/system-cleanup-script.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

# Caution | 注意事项

⚠️ This script irreversibly deletes user data. Please back up important files before use.

⚠️ 本脚本会不可逆删除用户数据，使用前请务必备份重要文件。

---

# Contact | 联系方式

GitHub: [SamueruTokeisou/serv00](https://github.com/SamueruTokeisou/serv00)
Telegram: [t.me/samuerutokeisou](https://t.me/samuerutokeisou)

---

# License | 许可证

MIT License © 2025 Tokeisou Samueru

```


```
