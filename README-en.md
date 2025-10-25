# 🚀 Serv00 System Reset Script - Enhanced Edition
Lightweight, intelligent, high-performance system reset solution designed specifically for Serv00 environment

<div align="center" style="margin-bottom: 24px;">
  <img src="https://img.shields.io/badge/Version-2.0_Beta-FF6B6B?style=flat-square&logo=rocket" alt="Version 2.0 Beta" />
  <img src="https://img.shields.io/badge/Serv00-Optimized-00DDEB?style=flat-square&logo=server" alt="Serv00 Optimized" />
  <img src="https://img.shields.io/badge/License-MIT-1E90FF?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/badge/Platform-Linux/FreeBSD-D91414?style=flat-square&logo=linux" alt="Platform" />
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash" alt="Bash" />
</div>

<div align="center" style="margin-bottom: 24px;">
  📖 <a href="README.md">中文简体</a> | 🌐 <a href="https://www.samueru.nyc.mn">Typecho Blog</a> | 📝 <a href="https://memos.286163668.xyz">Memos Notes</a> | 📡 <a href="https://x.com/SamueruTokeisou">X (Twitter)</a>
</div>

---

## 📋 Table of Contents

- [Introduction](#-introduction)
- [What's New](#-whats-new-v20-beta)
- [Quick Start](#-quick-start)
- [Features](#-features)
- [Usage Guide](#-usage-guide)
- [Technical Highlights](#-technical-highlights)
- [Installation](#-installation)
- [FAQ](#-faq)
- [Important Notes](#️-important-notes)
- [Contributing](#-contributing)
- [Changelog](#-changelog)

---

## 🌟 Introduction

**Serv00 System Reset Script - Enhanced Edition** is an intelligent system reset tool designed specifically for Serv00 VPS environments. It combines enterprise-grade security mechanisms with user-friendly interactive experience while maintaining lightweight efficiency.

### Why Choose the Enhanced Edition?

- ✅ **Zero Backup Design**: Leverages Serv00's built-in 7-day automatic backup mechanism
- ✅ **Process Self-Protection**: Solves the "self-termination" issue in the original script, ensuring complete cleanup execution
- ✅ **Smart Error Handling**: Every operation has status feedback and exception handling
- ✅ **Modular Design**: Supports independent execution of cron cleanup, process management, and more
- ✅ **Beautified Interface**: Color-coded status indicators, progress bars, countdown reminders

---

## 🎉 What's New (v2.0 Beta)

### 🛡️ Security Upgrades
- **Process Self-Protection**: Automatically excludes the script itself when cleaning user processes
- **Environment Pre-Check**: Validates necessary commands and system environment before startup
- **Signal Capture Handling**: Gracefully handles interrupt signals like Ctrl+C

### 🎨 User Experience Optimization
- **Color Progress Indicators**: Clear step displays like `[1/4]`, `[2/4]`
- **Status Symbol Feedback**: ✓ (Success), ✗ (Failed), ⚠ (Warning), → (In Progress)
- **Countdown Reminders**: 3-second countdown warning before dangerous operations
- **Beautified Menu Interface**: Blue border decoration, professional and elegant

### ⚡ Feature Enhancements
- **Independent Modules**: 5 independent operation options, flexible invocation
- **Smart Cache Cleanup**: Automatically cleans `.cache`, `.npm`, `.yarn` and other temporary directories
- **Environment Info Viewer**: Real-time view of disk, process, and file statistics
- **Optional Logging**: Operation logs automatically saved for traceability

---

## ⚡ Quick Start

### Beta Version (Recommended)
Experience the latest features with one command:

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script-beta.sh
chmod +x system-cleanup-script-beta.sh
./system-cleanup-script-beta.sh
```

### Stable Version
Classic version, simple and efficient:

```bash
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh
chmod +x system-cleanup-script.sh
./system-cleanup-script.sh
```

---

## 🔥 Features

### Core Functions

| Feature | Description | Advantages |
|---------|-------------|------------|
| 🗑️ **System Init** | Complete system environment cleanup | 4-step process, visualized progress |
| ⏰ **Cron Cleanup** | Clear all scheduled tasks | Independent invocation, fast execution |
| 🔄 **Process Management** | Terminate all user processes | Self-protection mechanism, safe and reliable |
| 📊 **Environment Info** | View system status | Disk, process, file statistics |
| 📝 **Operation Logs** | Record all operations | Convenient for auditing and troubleshooting |

### Cleanup Scope

#### Standard Cleanup Mode (Keep Configs)
- ✅ Delete all non-hidden files and directories
- ✅ Clean temporary cache directories (`.cache`, `.npm`, `.yarn`)
- ✅ Clear all cron scheduled tasks
- ✅ Terminate all user processes
- ❌ Keep user configuration files (`.bashrc`, `.ssh`, `.profile`)

#### Full Cleanup Mode
- ✅ Delete **ALL** files and directories (including hidden files)
- ✅ Keep only operation logs
- ⚠️ Use with caution, requires environment reconfiguration

### Smart Protection

- 🛡️ **Auto Protection**: Script won't be terminated by itself during runtime
- 🔒 **Log Protection**: Preserves log files during cleanup
- ⏱️ **Countdown Warning**: 3-second countdown before dangerous operations
- 💾 **Relies on Serv00 Backup**: No extra backup needed, reduces disk usage

---

## 📖 Usage Guide

### Main Menu Functions

After starting the script, you'll see:

```
╔════════════════════════════════════════════════════════╗
║      serv00 System Cleanup Script - SSH Panel         ║
║                Enhanced Edition 2.0                    ║
╚════════════════════════════════════════════════════════╝

  1. Initialize System (Cleanup Data)
  2. Clean Cron Tasks Only
  3. Clean User Processes Only
  4. View Environment Info
  5. Exit
```

### Option Details

#### 1️⃣ Initialize System
Complete system reset process:
- Clean cron scheduled tasks
- Clean special directories (`~/go`, cache, etc.)
- Clean home directory files
- Terminate user processes (may disconnect SSH)

**Use Cases**: Fresh deployment, environment contamination, system failures

#### 2️⃣ Clean Cron Tasks Only
Quickly clear all crontab scheduled tasks.

**Use Cases**: Cancel all scheduled scripts, reorganize tasks

#### 3️⃣ Clean User Processes Only
Terminate all user processes (SSH connection may disconnect).

**Use Cases**: Process deadlock, abnormal resource usage

#### 4️⃣ View Environment Info
Real-time display of:
- Username and home directory
- Disk usage
- Number of cron tasks
- Number of user processes
- File/directory statistics

**Use Cases**: Health check, pre-cleanup confirmation

---

## 💡 Technical Highlights

### Code Quality

```bash
# Process self-protection example
kill_user_proc() {
    local user=$(whoami)
    # Exclude current script process
    local processes=$(ps -u "$user" -o pid= | grep -v "^[[:space:]]*$SCRIPT_PID$")
    
    for pid in $processes; do
        kill -9 "$pid" 2>/dev/null
    done
}
```

### Security Mechanisms

- ✅ Uses `set -o pipefail` to catch pipeline errors
- ✅ Uses `mktemp` to create temporary files
- ✅ All operations have return value checks
- ✅ Signal capture for graceful exit

### Performance Optimization

- ⚡ No backup operations, fast execution
- ⚡ Minimized disk I/O
- ⚡ Modular design, execute on demand

---

## 🔧 Installation

### Permanent Installation (Recommended)

Install script to system path:

```bash
# Download Beta version
curl -O https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script-beta.sh

# Move to system directory
sudo mv system-cleanup-script-beta.sh /usr/local/bin/serv00-reset

# Add execute permission
sudo chmod +x /usr/local/bin/serv00-reset
```

Now you can run from anywhere:
```bash
serv00-reset
```

### Alias Method (Lightweight)

Add to Shell configuration file:

```bash
# Bash users
echo "alias serv00-reset='bash ~/system-cleanup-script-beta.sh'" >> ~/.bashrc
source ~/.bashrc

# Zsh users
echo "alias serv00-reset='bash ~/system-cleanup-script-beta.sh'" >> ~/.zshrc
source ~/.zshrc
```

---

## ❓ FAQ

### Q1: Why no backup feature?
**A:** Serv00 provides automatic 7-day backup service, no need for script backup. This design is lighter and executes faster.

### Q2: Will cleaning processes disconnect SSH?
**A:** Yes, because SSH connection is also a user process. The script will give a 3-second countdown warning before cleanup and execute cleanup as the last step.

### Q3: How to recover deleted files?
**A:** Contact Serv00 management panel and use the automatic backup recovery feature.

### Q4: Is the script safe?
**A:** Yes. All operations are within user permissions, no root privileges involved. Code is open source and auditable.

### Q5: What's the difference between Beta and Stable versions?
**A:** Beta version includes latest features (process self-protection, environment info, etc.), Stable version is the classic simple version. Beta version is recommended.

### Q6: Can I use it on other VPS?
**A:** Theoretically yes, but optimized specifically for Serv00. Please test carefully in other environments.

---

## ⚠️ Important Notes

### Must Read Before Use

1. **Data Security**
   - ⚠️ This script will **permanently delete** most data
   - ⚠️ Although Serv00 has automatic backup, manual backup of critical data is still recommended
   - ⚠️ Deletion operations are **irreversible**, please think twice

2. **SSH Connection**
   - ⚠️ Cleaning user processes will **disconnect SSH connection**
   - ✅ This is normal, you can reconnect after a few seconds

3. **Configuration Files**
   - ✅ Standard mode preserves `.bashrc`, `.ssh`, `.profile` and other configs
   - ⚠️ Full cleanup mode deletes all configs, requires reconfiguration

4. **Best Practices**
   - 📝 Before first use, select "View Environment Info" to understand system status
   - 🧪 Test on a test account first
   - 📋 Record important configuration information

---

## 🤝 Contributing

Welcome to participate in improving the system reset script!

### How to Contribute

1. **Fork this repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to branch** (`git push origin feature/AmazingFeature`)
5. **Submit Pull Request**

### Feedback Channels

- 🐛 [Submit Issue](https://github.com/SamueruTokeisou/serv00/issues)
- 💬 [X (Twitter)](https://x.com/SamueruTokeisou)
- 📧 Contact me through blog

### Contributors

Thanks to all contributors! 🎉

---

## 📜 Changelog

### v2.0 Beta (2025-10-25)

**New Features**
- ✨ Process self-protection mechanism
- ✨ Environment info viewer
- ✨ Independent module invocation (cron, process)
- ✨ Smart cache cleanup

**Improvements**
- 🎨 Beautified user interface
- 🛡️ Enhanced error handling
- ⚡ Improved execution speed
- 📝 Added operation logs

**Bug Fixes**
- 🐛 Fixed script interruption caused by process cleanup
- 🐛 Fixed edge cases in cron cleanup failures

### v1.0 (2024)

**Initial Release**
- 🎉 Basic system cleanup functionality
- 🎉 Cron task cleanup
- 🎉 User process management

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

---

## 🙏 Acknowledgments

- Thanks to [Serv00](https://serv00.com) for providing quality free VPS service
- Thanks to all users who use and provide feedback
- Thanks to the open source community for support

---

<div align="center">

### 🌟 If this project helps you, please give it a Star!

[![Star History Chart](https://api.star-history.com/svg?repos=SamueruTokeisou/serv00&type=Date)](https://star-history.com/#SamueruTokeisou/serv00&Date)

</div>

---

<footer align="center">
  <sub>© 2025 Tokeisou Samueru · System Reset, Conquer the Void · Code Simplification, Efficiency First</sub>
  <br>
  <sub>🚀 Made with ❤️ for Serv00 Community</sub>
</footer>
