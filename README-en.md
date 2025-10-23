# 🌌 Serv00 System Reset

A lightweight, high-speed script for resetting serv00.

<div align="center" style="margin-bottom: 24px;">
  <img src="https://img.shields.io/badge/Serv00-Reset-00DDEB?style=flat-square&logo=server" alt="Serv00 Reset" />
  <img src="https://img.shields.io/badge/License-MIT-1E90FF?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/badge/Platform-Linux/FreeBSD-D91414?style=flat-square&logo=linux" alt="Platform" />
  <img src="https://img.shields.io/badge/Language-中文-00DDEB?style=flat-square&logo=translate" alt="English/中文简体 README" />
</div>

<div align="center" style="margin-bottom: 24px;">
  📖 <a href="README-zh.md">中文</a> | 🌐 <a href="https://www.samueru.nyc.mn">Typecho Blog</a> | 📝 <a href="https://memos.286163668.xyz">Memos Notes</a> | 📡 <a href="https://x.com/SamueruTokeisou">X</a>
</div>

---

## Overview

**Serv00 System Reset** is a tool for quickly and securely initializing Serv00 VPS environments via SSH.

---

## Quick Start

Enter system reset mode with one command:

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```

---

## Features

- **Cleanup Tasks**:
  - Clear cron jobs.
  - Terminate user processes.
  - Clean home directory, preserving websites and configurations.

---

## Installation Instructions

Integrate seamlessly into your system:

```bash
sudo mv serv00-reset.sh /usr/local/bin/serv00-reset
```

Or set an alias:

```bash
echo "alias serv00-reset='~/serv00-reset.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## Caution

⚠️ This script deletes non-essential data. Back up critical files before starting.

---

## Contributions

Join the system reset! Fork this repository, submit Pull Requests, or share feedback on [X](https://x.com/SamueruTokeisou). Let's build a cleaner universe together!

<footer align="center">
  <sub>© 2025 Tokeisou Samueru · System Reset, Conquer the Void.</sub>
</footer>
