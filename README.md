# serv00

当然,我可以为您创建一个专门用于清理系统的简化脚本,包含一个简单的SSH面板和快速调用按键。以下是基于原脚本修改的版本:



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

这个脚本提供了以下功能:

1. 简化的SSH面板,只包含系统初始化(清理)选项。
2. 使用颜色输出,使界面更友好。
3. 在执行清理操作前会再次确认,以防止意外操作。
4. 提供了保留用户配置的选项。
5. 清理过程包括:清理cron任务、结束用户进程、删除用户目录下的文件。

要使用这个脚本:

1. 将脚本内容保存为文件,例如 `cleanup.sh`。
2. 给脚本添加执行权限: `chmod +x cleanup.sh`
3. 运行脚本: `./cleanup.sh`

为了实现快速调用,你可以:

1. 将脚本移动到 `/usr/local/bin/` 目录: `sudo mv cleanup.sh /usr/local/bin/cleanup`
2. 这样你就可以在任何目录下直接输入 `cleanup` 来运行脚本了。

或者,你可以在 `~/.bashrc` 或 `~/.bash_aliases` 文件中添加一个别名:

```bash
echo "alias cleanup='~/path/to/cleanup.sh'" >> ~/.bashrc
source ~/.bashrc
```

这样,你就可以直接输入 `cleanup` 来运行脚本了。

请注意,这个脚本有清理系统数据的功能,使用时要非常小心。建议在使用前先备份重要数据。
