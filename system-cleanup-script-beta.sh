#!/bin/bash

# serv00 系统重置脚本 - 精简增强版
# 版本: 2.0
# 说明: serv00 自带 7 天自动备份，本脚本专注于快速清理

set -o pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# 配置变量
LOG_FILE="$HOME/system_cleanup_$(date +%Y%m%d).log"
SCRIPT_PID=$$

# 辅助函数：打印彩色输出
red() {
    echo -e "${RED}$1${RESET}"
}

green() {
    echo -e "${GREEN}$1${RESET}"
}

yellow() {
    echo -e "${YELLOW}$1${RESET}"
}

blue() {
    echo -e "${BLUE}$1${RESET}"
}

# 日志记录（可选，不影响主要功能）
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

# 环境快速检查
check_env() {
    # 检查必要命令
    for cmd in whoami crontab pkill rm; do
        if ! command -v $cmd &> /dev/null; then
            red "错误: 缺少必要命令 $cmd"
            exit 1
        fi
    done
}

# 清理 cron 任务
clean_cron() {
    log "清理 cron 任务"
    local temp_cron=$(mktemp)
    
    if crontab "$temp_cron" 2>/dev/null; then
        green "✓ cron 任务已清理"
        log "Cron tasks cleared"
    else
        yellow "⚠ 清理 cron 任务失败（可能没有任务）"
        log "Failed to clear cron tasks"
    fi
    
    rm -f "$temp_cron" 2>/dev/null
}

# 安全地结束用户进程（保护脚本自身）
kill_user_proc() {
    local user=$(whoami)
    log "清理用户进程 (保护脚本 PID: $SCRIPT_PID)"
    
    # 获取所有用户进程，排除当前脚本
    local processes=$(ps -u "$user" -o pid= | grep -v "^[[:space:]]*$SCRIPT_PID$")
    
    if [ -z "$processes" ]; then
        yellow "⚠ 未找到需要清理的进程"
        return 0
    fi
    
    local count=0
    for pid in $processes; do
        if kill -9 "$pid" 2>/dev/null; then
            ((count++))
        fi
    done
    
    green "✓ 已清理 $count 个用户进程"
    log "Terminated $count processes"
}

# 清理特定目录
clean_directory() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        return 0
    fi
    
    chmod -R 755 "$dir" 2>/dev/null
    
    if rm -rf "$dir" 2>/dev/null; then
        green "✓ 已删除: $dir"
        log "Deleted: $dir"
    else
        yellow "⚠ 无法删除: $dir"
        log "Failed to delete: $dir"
    fi
}

# 系统初始化函数
init_server() {
    clear
    red "╔════════════════════════════════════════════════════════╗"
    red "║                警  告 - 危险操作                       ║"
    red "╚════════════════════════════════════════════════════════╝"
    echo ""
    yellow "此操作将："
    echo "  • 清空所有 cron 定时任务"
    echo "  • 终止所有用户进程"
    echo "  • 删除主目录中的大部分文件"
    echo ""
    blue "提示: serv00 自动保留最近 7 天的备份"
    echo ""
    
    read -p "$(red '确定要初始化系统吗？这将删除大部分数据。[y/n] [n]: ')" input
    input=${input:-n}
    
    if [[ "$input" != "y" ]] && [[ "$input" != "Y" ]]; then
        yellow "操作已取消"
        log "Operation cancelled"
        return 0
    fi
    
    echo ""
    read -p "是否保留用户配置文件（如 .bashrc, .ssh, .profile）？[y/n] [y]: " saveProfile
    saveProfile=${saveProfile:-y}
    
    echo ""
    blue "════════════════════════════════════════════════════════"
    green "开始系统初始化..."
    log "=== System initialization started ==="
    blue "════════════════════════════════════════════════════════"
    
    # 步骤1: 清理 cron 任务
    echo ""
    blue "[1/4] 清理 cron 定时任务"
    clean_cron
    
    # 步骤2: 清理特殊目录
    echo ""
    blue "[2/4] 清理特殊目录"
    if [ -d "$HOME/go" ]; then
        clean_directory "$HOME/go"
    fi
    
    # 清理常见缓存目录
    for cache_dir in ".cache" ".npm" ".yarn" ".cargo/registry" ".local/share/Trash"; do
        if [ -d "$HOME/$cache_dir" ]; then
            clean_directory "$HOME/$cache_dir"
        fi
    done
    
    # 步骤3: 清理主目录
    echo ""
    blue "[3/4] 清理主目录文件"
    
    if [[ "$saveProfile" == "y" ]] || [[ "$saveProfile" == "Y" ]]; then
        green "→ 保留隐藏配置文件模式"
        
        # 删除非隐藏文件和目录
        for item in "$HOME"/*; do
            if [ -e "$item" ]; then
                if rm -rf "$item" 2>/dev/null; then
                    log "Deleted: $item"
                else
                    yellow "⚠ 无法删除: $item"
                fi
            fi
        done
        
        green "✓ 已清理非隐藏文件（保留配置）"
        log "Cleaned non-hidden files"
    else
        yellow "→ 完全清理模式（包括隐藏文件）"
        
        # 删除所有文件（保护日志）
        for item in "$HOME"/{*,.[^.]*}; do
            if [ -e "$item" ] && [ "$item" != "$HOME/." ] && [ "$item" != "$HOME/.." ] \
               && [ "$item" != "$LOG_FILE" ]; then
                if rm -rf "$item" 2>/dev/null; then
                    log "Deleted: $item"
                else
                    yellow "⚠ 无法删除: $item"
                fi
            fi
        done
        
        green "✓ 已完全清理主目录"
        log "Cleaned all files including hidden"
    fi
    
    # 步骤4: 清理进程（最后执行）
    echo ""
    blue "[4/4] 清理用户进程"
    yellow "注意: 此操作将在 3 秒后执行，可能会断开 SSH 连接"
    sleep 1 && echo -n "3..." && sleep 1 && echo -n "2..." && sleep 1 && echo "1..."
    kill_user_proc
    
    echo ""
    blue "════════════════════════════════════════════════════════"
    green "✓ 系统初始化完成！"
    blue "════════════════════════════════════════════════════════"
    log "=== System initialization completed ==="
    
    echo ""
    yellow "提示："
    echo "  • serv00 自动保留最近 7 天的备份"
    echo "  • 如需恢复，请联系 serv00 管理面板"
    if [ -f "$LOG_FILE" ]; then
        echo "  • 操作日志: $LOG_FILE"
    fi
    echo ""
}

# 显示环境信息
show_info() {
    clear
    blue "╔════════════════════════════════════════════════════════╗"
    blue "║                  当前环境信息                          ║"
    blue "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "用户名称: $(whoami)"
    echo "主目录: $HOME"
    echo "当前路径: $(pwd)"
    echo ""
    
    # 磁盘使用情况
    if command -v df &> /dev/null; then
        echo "磁盘使用:"
        df -h "$HOME" 2>/dev/null | awk 'NR==2 {print "  已用: " $3 " / 总计: " $2 " (" $5 ")"}'
    fi
    echo ""
    
    # Cron 任务数量
    local cron_count=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
    echo "Cron 任务数: $cron_count"
    
    # 用户进程数
    local proc_count=$(ps -u $(whoami) 2>/dev/null | wc -l)
    echo "用户进程数: $proc_count"
    echo ""
    
    # 主目录文件统计
    local file_count=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    local dir_count=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo "主目录统计:"
    echo "  文件数: $file_count"
    echo "  目录数: $dir_count"
    
    blue "════════════════════════════════════════════════════════"
}

# 显示启动横幅
show_banner() {
    clear
    blue "╔════════════════════════════════════════════════════════════════════════════╗"
    green '  ____            _   _                 ____                _   '
    green ' / ___| _   _ ___| |_(_)_ __ ___      |  _ \ ___  ___  ___| |_ '
    green ' \___ \| | | / __| __| | '\''_ ` _ \     | |_) / _ \/ __|/ _ \ __|'
    green '  ___) | |_| \__ \ |_| | | | | | |    |  _ <  __/\__ \  __/ |_ '
    green ' |____/ \__, |___/\__|_|_| |_| |_|    |_| \_\___||___/\___|\__|'
    green '        |___/                                                   '
    echo ""
    yellow "                 🚀 serv00 系统重置脚本 - 精简增强版 v2.0"
    echo ""
    blue "╚════════════════════════════════════════════════════════════════════════════╝"
}

# 显示菜单
show_menu() {
    show_banner
    echo ""
    blue "═══════════════════════════[ 主菜单 ]══════════════════════════════"
    echo ""
    echo "  ${GREEN}1.${RESET} 🗑️  初始化系统（清理数据）"
    echo "  ${GREEN}2.${RESET} ⏰  仅清理 cron 任务"
    echo "  ${GREEN}3.${RESET} 🔄  仅清理用户进程"
    echo "  ${GREEN}4.${RESET} 📊  查看环境信息"
    echo "  ${GREEN}5.${RESET} 🚪  退出"
    echo ""
    blue "═══════════════════════════════════════════════════════════════════"
    echo ""
    read -p "请选择操作 [1-5]: " choice

    case $choice in
        1)
            init_server
            ;;
        2)
            echo ""
            blue "执行: 清理 cron 任务"
            clean_cron
            ;;
        3)
            echo ""
            yellow "警告: 此操作将终止所有用户进程（可能断开连接）"
            read -p "确认继续？[y/n] [n]: " confirm
            confirm=${confirm:-n}
            if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
                green "3 秒后执行..."
                sleep 3
                kill_user_proc
            else
                yellow "操作已取消"
            fi
            ;;
        4)
            show_info
            ;;
        5)
            echo ""
            read -p "$(yellow '确认退出脚本？[y/n] [y]: ')" exit_confirm
            exit_confirm=${exit_confirm:-y}
            if [[ "$exit_confirm" == "y" ]] || [[ "$exit_confirm" == "Y" ]]; then
                green "退出脚本"
                log "Script exited"
                exit 0
            fi
            ;;
        *)
            red "✗ 无效的选择，请输入 1-5"
            sleep 1
            ;;
    esac
}

# 信号捕获
trap 'log "Script interrupted"; exit 130' INT TERM

# 主程序
main() {
    check_env
    log "=== Script started by $(whoami) ==="
    
    while true; do
        show_menu
        echo ""
        read -p "按 Enter 键继续..." dummy
    done
}

# 启动
main
