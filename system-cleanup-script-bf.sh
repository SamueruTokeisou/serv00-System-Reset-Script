#!/bin/bash

# 定义霓虹色输出，打造高效界面
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# 辅助函数：为输出注入专业色彩
cyan() { echo -e "${CYAN}$1${RESET}"; }
red() { echo -e "${RED}$1${RESET}"; }
green() { echo -e "${GREEN}$1${RESET}"; }
yellow() { echo -e "${YELLOW}$1${RESET}"; }

# 清理计划任务
cleanCron() {
    echo "" > null
    crontab null
    rm null
    green "计划任务已清除！"
}

# 终止用户进程
killUserProc() {
    local user=$(whoami)
    pkill -u "$user" 2>/dev/null
    green "用户进程已终止！"
}

# 系统初始化：执行清理，保护网站目录及其内容
initServer() {
    cyan "🚀 启动系统重置协议..."
    read -p "$(red '警告：此操作将删除用户数据（网站除外）。是否继续？[y/n] [n]: ')" input
    input=${input:-n}

    if [[ "$input" == "y" ]] || [[ "$input" == "Y" ]]; then
        read -p "$(yellow '是否保留网站目录（如 ~/domains 及其内容）？[y/n] [y]: ')" saveWeb
        saveWeb=${saveWeb:-y}
        read -p "$(yellow '是否保留用户配置（如 ~/.bashrc）？[y/n] [y]: ')" saveProfile
        saveProfile=${saveProfile:-y}

        green "清除杂乱数据，保护你的数字资产..."

        # 清理计划任务
        cleanCron

        # 终止用户进程
        killUserProc

        # 清理磁盘，排除网站目录及其内容
        if [[ "$saveWeb" == "y" ]] || [[ "$saveWeb" == "Y" ]]; then
            if [ -d "$HOME/go" ]; then
                chmod -R 755 "$HOME/go" 2>/dev/null
                rm -rf "$HOME/go" 2>/dev/null
            fi
            find ~ -mindepth 1 -not -path "~/domains*" -not -path "~/go" -exec rm -rf {} + 2>/dev/null
        else
            if [ -d "$HOME/go" ]; then
                chmod -R 755 "$HOME/go" 2>/dev/null
                rm -rf "$HOME/go" 2>/dev/null
            fi
            find ~ -mindepth 1 -not -path "~/go" -exec rm -rf {} + 2>/dev/null
        fi

        # 可选保留用户配置
        if [[ "$saveProfile" != "y" ]] && [[ "$saveProfile" != "Y" ]]; then
            find ~ -maxdepth 1 -name ".*" -not -path "~" -not -name ".bashrc" -not -name ".profile" -exec rm -rf {} + 2>/dev/null
        fi

        cyan "系统重置完成，准备新任务！"
    else
        yellow "操作已中止，数据保持完整。"
    fi
}

# 显示清理工具菜单
showMenu() {
    clear
    cyan "========================================="
    cyan "         Serv00 重置：清理工具          "
    cyan "========================================="
    echo "1. 重置系统（清除数据，保留网站）"
    echo "2. 退出"
    cyan "========================================="
    read -p "选择操作 [1-2]: " choice

    case $choice in
        1)
            initServer
            ;;
        2)
            cyan "退出程序，保持高效！"
            exit 0
            ;;
        *)
            red "无效输入，请重新选择。"
            ;;
    esac
}

# 主循环
while true; do
    showMenu
    read -p "$(cyan '按 Enter 继续...')"
done
