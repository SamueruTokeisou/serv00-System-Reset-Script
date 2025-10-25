#!/bin/bash

# serv00 系统重置脚本 - 增强版
# 版本: 2.0
# 用途: 安全地清理和重置 serv00 环境

set -o pipefail  # 管道命令失败时返回错误

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# 配置变量
BACKUP_DIR="$HOME/backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$HOME/system_cleanup_$(date +%Y%m%d).log"
HOME_DIR="$HOME"
SCRIPT_PID=$$  # 当前脚本的进程ID

# 辅助函数：打印彩色输出并记录日志
red() { 
    echo -e "${RED}$1${RESET}" | tee -a "$LOG_FILE" >&2
}

green() { 
    echo -e "${GREEN}$1${RESET}" | tee -a "$LOG_FILE"
}

yellow() { 
    echo -e "${YELLOW}$1${RESET}" | tee -a "$LOG_FILE"
}

blue() { 
    echo -e "${BLUE}$1${RESET}" | tee -a "$LOG_FILE"
}

# 日志记录函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 错误处理函数
error_exit() {
    red "错误: $1"
    log "ERROR: $1"
    exit 1
}

# 环境检查
check_env() {
    log "=== 环境检查开始 ==="
    
    # 检查用户主目录
    if [ ! -d "$HOME_DIR" ]; then
        error_exit "用户主目录 $HOME_DIR 不存在"
    fi
    
    # 检查日志文件可写性
    if ! touch "$LOG_FILE" 2>/dev/null; then
        error_exit "无法创建日志文件 $LOG_FILE，请检查权限"
    fi
    
    # 检查必要命令
    local required_cmds="whoami crontab pkill find mkdir cp rm chmod"
    for cmd in $required_cmds; do
        if ! command -v $cmd &> /dev/null; then
            error_exit "缺少必要命令: $cmd"
        fi
    done
    
    # 检查磁盘空间（备份需要）
    local available_space=$(df -k "$HOME_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 102400 ]; then  # 小于100MB
        yellow "警告: 可用磁盘空间较少 ($(($available_space/1024))MB)，备份可能失败"
    fi
    
    log "环境检查通过"
    green "✓ 环境检查通过"
}

# 备份cron任务
backup_cron() {
    log "开始备份cron任务"
    local cron_backup="$BACKUP_DIR/crontab_$(whoami).bak"
    
    if crontab -l > "$cron_backup" 2>/dev/null; then
        green "✓ cron任务已备份到: $cron_backup"
        log "Cron tasks backed up to $cron_backup"
        return 0
    else
        yellow "⚠ 无cron任务或备份失败"
        log "No cron tasks or backup failed"
        return 1
    fi
}

# 清理cron任务
clean_cron() {
    log "开始清理cron任务"
    
    # 先备份
    backup_cron
    
    # 创建空的cron任务
    local temp_cron=$(mktemp)
    if crontab "$temp_cron" 2>/dev/null; then
        green "✓ cron任务已清理"
        log "Cron tasks cleared successfully"
        rm -f "$temp_cron"
        return 0
    else
        red "✗ 清理cron任务失败"
        log "Failed to clear cron tasks"
        rm -f "$temp_cron"
        return 1
    fi
}

# 备份文件/目录
backup_item() {
    local source="$1"
    local item_name=$(basename "$source")
    
    if [ ! -e "$source" ]; then
        log "跳过不存在的项目: $source"
        return 0
    fi
    
    # 确保备份目录存在
    if [ ! -d "$BACKUP_DIR" ]; then
        if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
            red "✗ 无法创建备份目录: $BACKUP_DIR"
            return 1
        fi
    fi
    
    # 执行备份
    if cp -rp "$source" "$BACKUP_DIR/" 2>/dev/null; then
        log "已备份: $source -> $BACKUP_DIR/$item_name"
        return 0
    else
        yellow "⚠ 备份失败: $source"
        log "Failed to backup: $source"
        return 1
    fi
}

# 安全地结束用户进程（保护脚本自身）
kill_user_processes() {
    local user=$(whoami)
    log "开始清理用户进程 (保护当前脚本 PID: $SCRIPT_PID)"
    
    # 获取所有用户进程，排除当前脚本及其父进程
    local processes=$(ps -u "$user" -o pid= | grep -v "^[[:space:]]*$SCRIPT_PID$" | grep -v "^[[:space:]]*$$PPID$")
    
    if [ -z "$processes" ]; then
        yellow "⚠ 未找到需要清理的进程"
        return 0
    fi
    
    local count=0
    for pid in $processes; do
        if kill -9 "$pid" 2>/dev/null; then
            ((count++))
            log "已终止进程: $pid"
        fi
    done
    
    green "✓ 已清理 $count 个用户进程"
    log "Terminated $count user processes"
}

# 清理特定目录
clean_directory() {
    local dir="$1"
    local dir_name=$(basename "$dir")
    
    if [ ! -d "$dir" ]; then
        log "目录不存在，跳过: $dir"
        return 0
    fi
    
    log "开始清理目录: $dir"
    
    # 备份
    backup_item "$dir"
    
    # 修改权限以确保可以删除
    chmod -R 755 "$dir" 2>/dev/null
    
    # 删除
    if rm -rf "$dir" 2>/dev/null; then
        green "✓ 已删除: $dir"
        log "Deleted directory: $dir"
        return 0
    else
        red "✗ 删除失败: $dir"
        log "Failed to delete: $dir"
        return 1
    fi
}

# 清理主目录内容
clean_home_directory() {
    local save_profile="$1"
    
    log "开始清理主目录 (保留配置: $save_profile)"
    
    # 创建备份目录
    if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
        error_exit "无法创建备份目录"
    fi
    
    if [[ "$save_profile" == "y" ]] || [[ "$save_profile" == "Y" ]]; then
        blue "→ 模式: 保留隐藏配置文件"
        
        # 备份并删除非隐藏文件
        for item in "$HOME_DIR"/*; do
            if [ -e "$item" ]; then
                backup_item "$item"
                if rm -rf "$item" 2>/dev/null; then
                    log "已删除: $item"
                else
                    yellow "⚠ 无法删除: $item"
                fi
            fi
        done
        
        # 删除特定的临时/缓存隐藏目录（保留重要配置）
        local dirs_to_clean=(".cache" ".local/share/Trash" ".npm" ".yarn" ".cargo/registry")
        for dir in "${dirs_to_clean[@]}"; do
            if [ -d "$HOME_DIR/$dir" ]; then
                clean_directory "$HOME_DIR/$dir"
            fi
        done
        
        green "✓ 已清理非隐藏文件和临时目录（保留配置文件）"
    else
        blue "→ 模式: 完全清理（包括隐藏文件）"
        
        # 备份所有内容
        yellow "正在备份主目录所有内容..."
        for item in "$HOME_DIR"/{*,.[^.]*}; do
            if [ -e "$item" ] && [ "$item" != "$HOME_DIR/." ] && [ "$item" != "$HOME_DIR/.." ]; then
                backup_item "$item"
            fi
        done
        
        # 删除所有内容（除了当前备份目录和日志）
        for item in "$HOME_DIR"/{*,.[^.]*}; do
            if [ -e "$item" ] && [ "$item" != "$HOME_DIR/." ] && [ "$item" != "$HOME_DIR/.." ] \
               && [ "$item" != "$BACKUP_DIR" ] && [ "$item" != "$LOG_FILE" ]; then
                if rm -rf "$item" 2>/dev/null; then
                    log "已删除: $item"
                else
                    yellow "⚠ 无法删除: $item"
                fi
            fi
        done
        
        green "✓ 已完全清理主目录"
    fi
}

# 显示备份信息
show_backup_info() {
    if [ -d "$BACKUP_DIR" ]; then
        local backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        blue "\n=== 备份信息 ==="
        echo "备份位置: $BACKUP_DIR"
        echo "备份大小: ${backup_size:-未知}"
        echo "日志文件: $LOG_FILE"
        blue "===============\n"
        log "Backup completed - Location: $BACKUP_DIR, Size: $backup_size"
    fi
}

# 系统初始化主函数
init_server() {
    clear
    red "╔════════════════════════════════════════════════════════╗"
    red "║             警  告 - 危险操作                          ║"
    red "╚════════════════════════════════════════════════════════╝"
    echo ""
    yellow "此操作将："
    echo "  • 清空所有 cron 定时任务"
    echo "  • 终止所有用户进程"
    echo "  • 删除主目录中的大部分文件"
    echo "  • 所有数据将被备份到: $BACKUP_DIR"
    echo ""
    
    read -p "$(red '是否继续系统初始化？[y/n] [n]: ')" input
    input=${input:-n}
    
    if [[ "$input" != "y" ]] && [[ "$input" != "Y" ]]; then
        yellow "操作已取消"
        log "Operation cancelled by user"
        return 0
    fi
    
    echo ""
    read -p "是否保留用户配置文件（如 .bashrc, .ssh, .profile）？[y/n] [y]: " save_profile
    save_profile=${save_profile:-y}
    
    echo ""
    blue "════════════════════════════════════════════════════════"
    green "开始系统初始化..."
    log "=== System initialization started ==="
    blue "════════════════════════════════════════════════════════"
    
    # 步骤1: 清理 cron 任务
    echo ""
    blue "[1/5] 清理 cron 定时任务"
    clean_cron
    
    # 步骤2: 清理特殊目录（go）
    echo ""
    blue "[2/5] 清理特殊目录"
    if [ -d "$HOME_DIR/go" ]; then
        clean_directory "$HOME_DIR/go"
    else
        yellow "⚠ 目录不存在: $HOME_DIR/go"
    fi
    
    # 步骤3: 清理主目录
    echo ""
    blue "[3/5] 清理主目录文件"
    clean_home_directory "$save_profile"
    
    # 步骤4: 显示备份信息
    echo ""
    blue "[4/5] 备份完成"
    show_backup_info
    
    # 步骤5: 清理进程（最后执行，避免中断脚本）
    echo ""
    blue "[5/5] 清理用户进程"
    yellow "注意: 此操作将在 3 秒后执行，并可能断开 SSH 连接"
    sleep 3
    kill_user_processes
    
    echo ""
    blue "════════════════════════════════════════════════════════"
    green "✓ 系统初始化完成！"
    blue "════════════════════════════════════════════════════════"
    log "=== System initialization completed ==="
    
    echo ""
    yellow "提示："
    echo "  1. 备份保存在: $BACKUP_DIR"
    echo "  2. 日志保存在: $LOG_FILE"
    echo "  3. 如需恢复，请从备份目录复制文件"
    echo ""
}

# 显示菜单
show_menu() {
    clear
    echo ""
    blue "╔════════════════════════════════════════════════════════╗"
    blue "║          serv00 系统清理脚本 - SSH 管理面板           ║"
    blue "║                    版本: 2.0 增强版                    ║"
    blue "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "  1. 初始化系统（清理数据）"
    echo "  2. 仅清理 cron 任务"
    echo "  3. 仅清理用户进程"
    echo "  4. 查看当前环境信息"
    echo "  5. 退出"
    echo ""
    blue "════════════════════════════════════════════════════════"
    echo ""
    read -p "请选择操作 [1-5]: " choice

    case $choice in
        1)
            init_server
            ;;
        2)
            echo ""
            green "执行: 清理 cron 任务"
            clean_cron
            ;;
        3)
            echo ""
            yellow "警告: 此操作将终止所有用户进程（可能断开连接）"
            read -p "确认继续？[y/n] [n]: " confirm
            if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
                kill_user_processes
            else
                yellow "操作已取消"
            fi
            ;;
        4)
            echo ""
            blue "=== 当前环境信息 ==="
            echo "用户: $(whoami)"
            echo "主目录: $HOME"
            echo "磁盘使用: $(df -h "$HOME" | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
            echo "Cron 任务数: $(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)"
            echo "用户进程数: $(ps -u $(whoami) | wc -l)"
            blue "===================="
            ;;
        5)
            echo ""
            read -p "$(yellow '确认退出脚本？[y/n] [y]: ')" exit_confirm
            exit_confirm=${exit_confirm:-y}
            if [[ "$exit_confirm" == "y" ]] || [[ "$exit_confirm" == "Y" ]]; then
                green "退出脚本"
                log "Script exited normally"
                exit 0
            fi
            ;;
        *)
            red "✗ 无效的选择，请输入 1-5"
            log "Invalid choice: $choice"
            sleep 2
            ;;
    esac
}

# 主程序入口
main() {
    # 环境检查
    check_env
    
    # 显示启动信息
    green "日志记录在: $LOG_FILE"
    log "=== Script started ==="
    log "User: $(whoami), Home: $HOME"
    
    # 主循环
    while true; do
        show_menu
        echo ""
        read -p "按 Enter 键继续..." dummy
    done
}

# 捕获退出信号
trap 'log "Script interrupted"; exit 130' INT TERM

# 启动主程序
main
