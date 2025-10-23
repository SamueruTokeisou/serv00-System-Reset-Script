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
        # 清理 $HOME/go 文件夹
        if [ -d "$HOME/go" ]; then
            chmod -R 755 "$HOME/go" 2>/dev/null
            rm -rf "$HOME/go" 2>/dev/null
        fi
        
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
    echo "           ____                   ___   ___
 / ___|  ___ _ ____   __/ _ \ / _ \  ___ ___  _ __ ___
 \___ \ / _ \ '__\ \ / / | | | | | |/ __/ _ \| '_ ` _ \
  ___) |  __/ |   \ V /| |_| | |_| | (_| (_) | | | | | |
 |____/ \___|_|    \_/  \___/ \___(_)___\___/|_| |_| |_|
  Revolutionary Free Hosting   ᴘᴏᴡᴇʀᴇᴅ ʙʏ hostᴜɴᴏ.com          "
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
