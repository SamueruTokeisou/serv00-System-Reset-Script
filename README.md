# serv00 系统重置脚本 | serv00 System Reset Script

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![ShellCheck](https://github.com/SamueruTokeisou/serv00/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/SamueruTokeisou/serv00/actions/workflows/shellcheck.yml)
[![Release](https://img.shields.io/github/v/release/SamueruTokeisou/serv00)](https://github.com/SamueruTokeisou/serv00/releases)

---

## 目录

- [简介](#简介)
- [功能特性](#功能特性)
- [安装与使用](#安装与使用)
- [高级配置](#高级配置)
- [注意事项](#注意事项)
- [贡献](#贡献)
- [许可证](#许可证)

---

## 简介

**serv00** 是一个轻量且实用的系统重置脚本，专为通过 SSH 远程快速初始化和清理服务器而设计。  
它集成了基本的清理功能，并添加多重确认机制以防止误删数据。  

---

## 功能特性

- 简洁易用的命令行交互界面  
- 彩色输出提升阅读体验  
- 操作前多重确认，避免误操作  
- 可选择保留用户配置信息  
- 清理任务涵盖：
  - 计划任务（cron）清空  
  - 用户进程强制终止  
  - 用户主目录清理  

---

## 安装与使用

### 快速启动

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
