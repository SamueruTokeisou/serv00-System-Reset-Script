# serv00系统重置脚本




# serv00 System Reset Script

[English](#english) | [中文简体](#中文简体)

---

## <a name="中文简体"></a>中文简体

<!-- 在此处填充中文内容 -->

**serv00** 一个简单的系统重置脚本，帮助您通过 SSH 终端轻松初始化服务器。该脚本提供了一些基础的清理和系统初始化操作，并且在执行前会进行确认，防止误操作。

## 特性

- **简化的 SSH 面板**：只包含系统初始化（清理）选项。
- **友好的界面**：使用颜色输出，便于阅读。
- **确认操作**：在执行清理任务前，会提示确认操作，确保不会误删数据。
- **用户配置保留选项**：允许保留用户配置文件。
- **多项清理任务**：
  - 清理 `cron` 任务。
  - 结束当前用户的所有进程。
  - 删除用户目录下的文件。

## 一键运行脚本

通过以下命令，您可以一键从 GitHub 下载并运行该脚本：

```bash
curl -s https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh | bash
```

## 如何手动使用脚本

1. 下载脚本并保存为 `cleanup.sh`。
2. 赋予执行权限：
   ```bash
   chmod +x cleanup.sh
   ```
3. 运行脚本：
   ```bash
   ./cleanup.sh
   ```

### 快速调用设置

如果希望在系统中快速调用该脚本，您可以将其移动到全局路径：

```bash
sudo mv cleanup.sh /usr/local/bin/cleanup
```

这样，您可以通过输入 `cleanup` 来随时运行脚本。

### 设置别名

或者，您可以在 `.bashrc` 或 `.bash_aliases` 中添加别名，方便调用：

```bash
echo "alias cleanup='~/path/to/cleanup.sh'" >> ~/.bashrc
source ~/.bashrc
```

通过这种方式，您只需输入 `cleanup` 就能运行脚本。

## 注意事项

- **该脚本将删除用户数据**，请在执行前确保备份重要数据。
- 适用于需要快速清理和初始化的服务器环境，请谨慎使用。

---

### 脚本内容

以下是脚本的详细内容，供您参考：

```bash
#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# 辅助函数
red() {
    echo -e "${RED}$1${RESET}"
}

green() {
    echo -e "${GREEN}$1${RESET}"
}

yellow() {
    echo -e "${YELLOW}$1${RESET}"
}

# 清理cron任务
cleanCron() {
    echo "" > null
    crontab null
    rm null
}

# 结束所有用户进程
killUserProc() {
    local user=$(whoami)
    pkill -kill -u $user
}

# 系统初始化函数
initServer() {
    read -p "$(red "确定要初始化系统吗？这将删除大部分数据。 [y/n] [n]: ")" input
    input=${input:-n}
    
    if [[ "$input" == "y" ]] || [[ "$input" == "Y" ]]; then
        read -p "是否保留用户配置？[y/n] [y]: " saveProfile
        saveProfile=${saveProfile:-y}

        green "清理cron任务..."
        cleanCron

        green "清理用户进程..."
        killUserProc

        green "清理磁盘..."
        if [[ "$saveProfile" = "y" ]] || [[ "$saveProfile" = "Y" ]]; then
            rm -rf ~/* 2>/dev/null
        else
            rm -rf ~/* ~/.* 2>/dev/null
        fi

        yellow "系统初始化完成"
    else
        yellow "操作已取消"
    fi
}

# 显示菜单
showMenu() {
    clear
    echo "========================================="
    echo "         系统清理脚本 - SSH面板          "
    echo "========================================="
    echo "1. 初始化系统（清理数据）"
    echo "2. 退出"
    echo "========================================="
    read -p "请选择操作 [1-2]: " choice

    case $choice in
        1)
            initServer
            ;;
        2)
            echo "退出脚本"
            exit 0
            ;;
        *)
            red "无效的选择，请重新输入"
            ;;
    esac
}

# 主循环
while true; do
    showMenu
    read -p "按Enter键继续..."
done
```

---

**免责声明**：该脚本具有清理系统的功能，运行时请谨慎操作，避免误删重要数据。
```

---

## <a name="english"></a>English

<!-- 在此处填充英文内容 -->
```md
# serv00 System Reset Script

**serv00** is a simple system reset script that helps you easily initialize a server through the SSH terminal. The script provides basic cleaning and system initialization tasks with confirmation prompts to prevent accidental actions.

## Features

- **Simplified SSH Panel**: Includes only system initialization (cleanup) options.
- **User-Friendly Interface**: Uses color-coded output for easier readability.
- **Confirmation Prompts**: Ensures that tasks are confirmed before execution to avoid accidental data loss.
- **Option to Retain User Configurations**: Allows you to keep user configuration files if desired.
- **Comprehensive Cleanup Tasks**:
  - Clears `cron` jobs.
  - Terminates all processes of the current user.
  - Deletes files from the user's home directory.

## Run the Script in One Command

Simply run the following command in the terminal to download and execute the script:

```bash
curl -s https://raw.githubusercontent.com/SamueruTokeisou/serv00/main/system-cleanup-script.sh | bash
```

## How to Manually Use the Script

1. Download the script and save it as `cleanup.sh`.
2. Give it execution permission:
   ```bash
   chmod +x cleanup.sh
   ```
3. Run the script:
   ```bash
   ./cleanup.sh
   ```

### Quick Access Setup

To easily access the script, move it to a global path:

```bash
sudo mv cleanup.sh /usr/local/bin/cleanup
```

Now, you can run the script by typing `cleanup` in the terminal from any directory.

### Alias Setup

Alternatively, you can add an alias in your `.bashrc` or `.bash_aliases` file:

```bash
echo "alias cleanup='~/path/to/cleanup.sh'" >> ~/.bashrc
source ~/.bashrc
```

With this alias, you can just type `cleanup` to run the script.

## Important Notes

- **This script deletes user data**. Ensure you back up any important data before running it.
- Suitable for server environments where quick cleanup and initialization are needed. Please use it with caution.

---

### Script Content

Here is the full content of the script for reference:

```bash
#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Helper functions
red() {
    echo -e "${RED}$1${RESET}"
}

green() {
    echo -e "${GREEN}$1${RESET}"
}

yellow() {
    echo -e "${YELLOW}$1${RESET}"
}

# Clean cron jobs
cleanCron() {
    echo "" > null
    crontab null
    rm null
}

# Kill all user processes
killUserProc() {
    local user=$(whoami)
    pkill -kill -u $user
}

# System initialization function
initServer() {
    read -p "$(red "Are you sure you want to initialize the system? This will delete most data. [y/n] [n]: ")" input
    input=${input:-n}
    
    if [[ "$input" == "y" ]] || [[ "$input" == "Y" ]]; then
        read -p "Do you want to keep user configurations? [y/n] [y]: " saveProfile
        saveProfile=${saveProfile:-y}

        green "Cleaning cron jobs..."
        cleanCron

        green "Cleaning user processes..."
        killUserProc

        green "Cleaning disk..."
        if [[ "$saveProfile" == "y" ]] || [[ "$saveProfile" == "Y" ]]; then
            rm -rf ~/* 2>/dev/null
        else
            rm -rf ~/* ~/.* 2>/dev/null
        fi

        yellow "System initialization complete."
    else
        yellow "Operation canceled."
    fi
}

# Show menu
showMenu() {
    clear
    echo "========================================="
    echo "      System Cleanup Script - SSH Panel   "
    echo "========================================="
    echo "1. Initialize System (Cleanup)"
    echo "2. Exit"
    echo "========================================="
    read -p "Select an option [1-2]: " choice

    case $choice in
        1)
            initServer
            ;;
        2)
            echo "Exiting script"
            exit 0
            ;;
        *)
            red "Invalid choice, please try again."
            ;;
    esac
}

# Main loop
while true; do
    showMenu
    read -p "Press Enter to continue..."
done
```






