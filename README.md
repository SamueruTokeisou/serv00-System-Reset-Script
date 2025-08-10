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


#  升级Go 语言环境

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
好的，我帮你整理一个简洁实用的 Serv00 上 Typecho 及主题一键安装命令，并附带一份适合发布在 GitHub 的介绍文章模板。

---

## 一键安装命令（适用于 Serv00）

```bash
# 进入网站目录
cd ~/domains/www.samueru.nyc.mn/public_html || mkdir -p ~/domains/www.samueru.nyc.mn/public_html && cd ~/domains/www.samueru.nyc.mn/public_html

# 清空目录（⚠请先备份）
rm -rf ./*

# 下载 Typecho 最新稳定版
wget -O typecho.zip https://github.com/typecho/typecho/releases/latest/download/typecho.zip

# 解压并删除压缩包
unzip typecho.zip && rm typecho.zip

# 进入主题目录，若不存在则创建
mkdir -p usr/themes && cd usr/themes

# 删除旧主题（可选）
rm -rf MWordStar

# 下载 MWordStar 主题最新版本
wget -O MWordStar.zip https://github.com/changbin1997/MWordStar/releases/latest/download/MWordStar-2.6-bundle.zip

# 解压主题并删除压缩包
unzip MWordStar.zip && rm MWordStar.zip

# 重命名主题文件夹
mv MWordStar-2.6 MWordStar
```

---

## GitHub 介绍文章模板（README.md）

````markdown
# Typecho 一键安装脚本（Serv00 专用）

这是一个针对 Serv00 主机环境设计的 Typecho 博客系统及 MWordStar 主题的一键安装脚本，适合喜欢轻量级且功能丰富博客的你。

---

## 功能

- 自动下载并安装 Typecho 最新稳定版
- 自动下载并安装 MWordStar 主题最新版本
- 目录清理，避免旧文件干扰
- 适配 Serv00 环境（512MB 内存）

---

## 使用说明

1. 登录你的 Serv00 主机，通过 SSH 进入网站根目录：
   ```bash
   cd ~/domains/www.samueru.nyc.mn/public_html
````

2. 备份好你的现有数据，运行一键安装命令：

   ```bash
   # 粘贴上方的一键安装脚本执行即可
   ```

3. 访问你的网站，进入 Typecho 安装界面，完成数据库配置和管理员账号设置。

4. 进入后台启用 MWordStar 主题，开始你的博客之旅。

---

## 适用环境

* Serv00 免费主机或付费主机，PHP 环境支持 Typecho 运行
* 建议 PHP 版本 7.4+
* 512MB 内存以上（根据主题大小和插件情况有所不同）

---

## 备注

* 请务必备份重要数据，以防不测
* 本脚本不修改数据库，重复执行不会影响数据库内容
* 主题可替换，替换时只需更改主题下载链接和文件夹名即可

---

## 贡献

欢迎提 issue 或 PR，改善脚本适用性和功能。

---

## 相关链接

* [Typecho 官方网站](https://typecho.org)
* [MWordStar 主题仓库](https://github.com/changbin1997/MWordStar)
* [Serv00 主机服务](https://serv00.com)

---

> 作者：Tokeisou Samueru
> 维护者：\[你的 GitHub 账号链接]
> 联系邮箱：\[你的邮箱]

```

---

如果需要我帮你生成更个性化的版本，或者配合其他主题，也可以告诉我。这样你在 GitHub 发布后，别人一看就能明白怎么快速部署你的环境。
```


