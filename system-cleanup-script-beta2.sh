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
CYAN='\033[0;36m'
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

cyan() {
    echo -e "${CYAN}$1${RESET}"
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

# 恢复 Web 默认设置
restore_web_defaults() {
    local username=$(whoami)
    local domain_dir="$HOME/domains/$username.serv00.net/public_html"
    local logs_dir="$HOME/domains/$username.serv00.net/logs"
    local index_file="$domain_dir/index.html"
    
    log "恢复 Web 默认设置"
    blue "→ 恢复 Web 默认设置..."
    
    # 创建 domains 目录结构
    if mkdir -p "$domain_dir" 2>/dev/null; then
        chmod 755 "$domain_dir"
        log "Created directory: $domain_dir"
    fi
    
    # 创建 logs 目录
    if mkdir -p "$logs_dir" 2>/dev/null; then
        chmod 755 "$logs_dir"
        log "Created directory: $logs_dir"
    fi
    
    # 创建默认 index.html
    cat > "$index_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$username.serv00.net</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>Welcome to $username.serv00.net</h1>
    <p>Your web server is working!</p>
</body>
</html>
EOF
    
    if [ -f "$index_file" ]; then
        chmod 644 "$index_file"
        green "✓ 已恢复默认网站: $domain_dir"
        log "Restored default website"
    else
        yellow "⚠ 无法创建默认网站文件"
    fi
}

# 快照恢复功能
snapshot_recovery() {
    clear
    blue "╔════════════════════════════════════════════════════════════╗"
    blue "║                  快照恢复系统                              ║"
    blue "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    local backup_dir="$HOME/backups/local"
    
    # 检查备份目录是否存在
    if [ ! -d "$backup_dir" ]; then
        red "✗ 备份目录不存在: $backup_dir"
        yellow "提示: serv00 的自动备份可能未启用或备份位置不同"
        return 1
    fi
    
    cd "$backup_dir" || return 1
    
    # 定义关联数组存储快照
    declare -A snapshot_paths
    
    # 遍历符号链接，提取快照信息
    while read -r line; do
        folder=$(echo "$line" | awk '{print $9}')
        real_path=$(echo "$line" | awk '{print $11}')
        
        if [ -n "$folder" ] && [ -n "$real_path" ]; then
            snapshot_paths["$folder"]="$real_path"
        fi
    done < <(ls -trl 2>/dev/null | grep -F "lrwxr")
    
    local size=${#snapshot_paths[@]}
    
    if [ $size -eq 0 ]; then
        yellow "⚠ 未找到可用的备份快照"
        echo ""
        echo "提示："
        echo "  • serv00 会自动创建每日备份"
        echo "  • 备份保留 7 天"
        echo "  • 备份位置: ~/backups/local/"
        return 0
    fi
    
    # 按日期排序
    local sorted_keys=($(echo "${!snapshot_paths[@]}" | tr ' ' '\n' | sort -r))
    
    echo "选择恢复类型："
    echo "  ${CYAN}[1]${RESET} 完整快照恢复（恢复整个主目录）"
    echo "  ${CYAN}[2]${RESET} 恢复指定文件或目录"
    echo "  ${CYAN}[0]${RESET} 返回主菜单"
    echo ""
    read -p "请选择 [1-2]: " recovery_type
    
    case $recovery_type in
        1)
            # 完整恢复
            echo ""
            blue "可用的备份快照："
            blue "────────────────────────────────────────────────────────────"
            local i=1
            for folder in "${sorted_keys[@]}"; do
                echo "  ${CYAN}[$i]${RESET} $folder"
                i=$((i + 1))
            done
            echo ""
            
            local retries=3
            while [ $retries -gt 0 ]; do
                read -p "请选择要恢复的快照编号 [1-$size]: " input
                
                if [[ $input =~ ^[0-9]+$ ]] && [ "$input" -gt 0 ] && [ "$input" -le $size ]; then
                    local target_folder="${sorted_keys[$((input - 1))]}"
                    local src_path="${snapshot_paths[$target_folder]}"
                    
                    echo ""
                    red "警告: 此操作将删除当前所有文件并恢复到 $target_folder"
                    read -p "确认继续？[y/n] [n]: " confirm
                    confirm=${confirm:-n}
                    
                    if [[ "$confirm" != "y" ]]; then
                        yellow "操作已取消"
                        return 0
                    fi
                    
                    echo ""
                    blue "→ 开始恢复快照..."
                    log "Snapshot recovery started: $target_folder"
                    
                    # 清理用户进程
                    yellow "注意: 将终止所有进程并断开连接..."
                    sleep 2
                    
                    # 删除当前文件
                    rm -rf "$HOME"/* 2>/dev/null
                    
                    # 使用 rsync 恢复
                    if rsync -a "$src_path/" "$HOME/" 2>/dev/null; then
                        green "✓ 快照恢复完成"
                        log "Snapshot recovery completed: $target_folder"
                    else
                        red "✗ 快照恢复失败"
                        log "Snapshot recovery failed"
                    fi
                    
                    # 最后清理进程
                    kill_user_processes
                    return 0
                else
                    retries=$((retries - 1))
                    red "✗ 输入无效，还有 $retries 次机会"
                fi
            done
            
            red "输入错误次数过多，操作已取消"
            return 1
            ;;
            
        2)
            # 恢复指定文件
            echo ""
            read -p "输入要恢复的文件或目录名称: " search_name
            
            if [ -z "$search_name" ]; then
                red "✗ 文件名不能为空"
                return 1
            fi
            
            # 搜索文件
            declare -A found_files
            local found_count=0
            
            blue "→ 搜索文件中..."
            for folder in "${!snapshot_paths[@]}"; do
                local path="${snapshot_paths[$folder]}"
                local results=$(find "$path" -name "$search_name" 2>/dev/null)
                
                if [ -n "$results" ]; then
                    found_files["$folder"]="$results"
                    ((found_count++))
                fi
            done
            
            if [ $found_count -eq 0 ]; then
                yellow "⚠ 未找到匹配的文件: $search_name"
                return 0
            fi
            
            # 显示搜索结果
            echo ""
            green "找到以下文件："
            blue "────────────────────────────────────────────────────────────"
            
            local sorted_found=($(echo "${!found_files[@]}" | tr ' ' '\n' | sort -r))
            declare -A index_path_map
            
            local i=1
            for folder in "${sorted_found[@]}"; do
                echo "${CYAN}$i.${RESET} 快照日期: $folder"
                local results="${found_files[$folder]}"
                IFS=
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
    red "╔════════════════════════════════════════════════════════════╗"
    red "║                警  告 - 危险操作                           ║"
    red "╚════════════════════════════════════════════════════════════╝"
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
    blue "════════════════════════════════════════════════════════════"
    green "开始系统初始化..."
    log "=== System initialization started ==="
    blue "════════════════════════════════════════════════════════════"
    
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
    blue "════════════════════════════════════════════════════════════"
    green "✓ 系统初始化完成！"
    blue "════════════════════════════════════════════════════════════"
    log "=== System initialization completed ==="
    
    echo ""
    yellow "💡 提示："
    echo "    • serv00 自动保留最近 7 天的备份"
    echo "    • 如需恢复，可使用菜单中的「快照恢复系统」功能"
    echo "    • 已自动恢复默认网站目录和日志目录"
    if [ -f "$LOG_FILE" ]; then
        echo "    • 操作日志: $LOG_FILE"
    fi
    echo ""
}

# 显示环境信息
show_info() {
    clear
    echo ""
    echo -e "${CYAN}     ______            _                                      __  ${RESET}"
    echo -e "${CYAN}    / ____/___ _   __ (_)_____ ____   ____   ____ ___  ___  / /_ ${RESET}"
    echo -e "${CYAN}   / __/  / __  | / / / // ___// __  / / __  / / __  __ \/ _ \/ __/ ${RESET}"
    echo -e "${CYAN}  / /___ / / / / |/ / / // /   / /_/ // / / // / / / / / /  __/ / / /${RESET}"
    echo -e "${CYAN} /_____//_/ /_/|___//_//_/    \____//_/ /_//_/ /_/ /_/\___/_/ /_/ ${RESET}"
    echo ""
    yellow "                    📊 环境状态监控面板"
    blue   "                    ━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
        
    green "  ┌────────────────────────────────────────────────────────────┐"
    echo "  │ 用户名称: $(whoami)"
    echo "  │ 主目录: $HOME"
    echo "  │ 当前路径: $(pwd)"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
    
    # 磁盘使用情况
    if command -v df &> /dev/null; then
        green "  ┌─[ 💾 磁盘使用 ]─────────────────────────────────────────────┐"
        df -h "$HOME" 2>/dev/null | awk 'NR==2 {print "  │ 已用: " $3 " / 总计: " $2 " (" $5 ")                     │"}'
        green "  └────────────────────────────────────────────────────────────┘"
    fi
    echo ""
    
    # Cron 任务数量
    green "  ┌─[ ⏰ 定时任务 ]─────────────────────────────────────────────┐"
    local cron_count=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^

# 显示启动横幅
show_banner() {
    clear
    echo ""
    blue "╔════════════════════════════════════════════════════════════╗"
    blue "║          serv00 系统清理脚本 - SSH 管理面板               ║"
    blue "║                   精简增强版 v2.0                          ║"
    blue "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# 显示菜单
show_menu() {
    show_banner
    echo "  ${CYAN}[1]${RESET} 🗑️  初始化系统（清理数据）"
    echo "  ${CYAN}[2]${RESET} ⏰  仅清理 cron 任务"
    echo "  ${CYAN}[3]${RESET} 🔄  仅清理用户进程"
    echo "  ${CYAN}[4]${RESET} 📊  查看环境信息"
    echo "  ${CYAN}[5]${RESET} 💾  快照恢复系统"
    echo "  ${CYAN}[6]${RESET} 🚪  退出"
    echo ""
    blue "════════════════════════════════════════════════════════════"
    echo ""
    read -p "请选择操作 [1-6]: " choice

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
main | wc -l)
    echo "  │ Cron 任务数: $cron_count                                        │"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
    
    # 用户进程数
    green "  ┌─[ 🔄 进程统计 ]─────────────────────────────────────────────┐"
    local proc_count=$(ps -u $(whoami) 2>/dev/null | wc -l)
    echo "  │ 用户进程数: $proc_count                                         │"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
    
    # 主目录文件统计
    green "  ┌─[ 📁 文件统计 ]─────────────────────────────────────────────┐"
    local file_count=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    local dir_count=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo "  │ 文件数: $file_count                                             │"
    echo "  │ 目录数: $dir_count                                              │"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
}

# 显示启动横幅
show_banner() {
    clear
    echo ""
    cyan '     _____           __               ____                 __  '
    cyan '    / ___/__  _____ / /____  ____ _  / __ \___  ________  / /_ '
    cyan '    \__ \/ / / / __ `/ __/ / / __ `/ / /_/ / _ \/ ___/ _ \/ __/ '
    cyan '   ___/ / /_/ / /_/ / /_/ /_/ /_/ / / _, _/  __(__  )  __/ /_   '
    cyan '  /____/\__, /\__,_/\__/\__/\__,_/ /_/ |_|\___/____/\___/\__/   '
    cyan '       /____/                                                    '
    echo ""
    yellow "           serv00 System Reset Script - Enhanced v2.0"
    blue   "           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 显示菜单
show_menu() {
    show_banner
    green "  ╔════════════════════════════════════════════════════════════╗"
    green "  ║                       主 菜 单                             ║"
    green "  ╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "    ${CYAN}[1]${RESET} 🗑️  初始化系统 ${YELLOW}(清理所有数据)${RESET}"
    echo "    ${CYAN}[2]${RESET} ⏰  清理 Cron 任务"
    echo "    ${CYAN}[3]${RESET} 🔄  清理用户进程"
    echo "    ${CYAN}[4]${RESET} 📊  查看环境信息"
    echo "    ${CYAN}[5]${RESET} 🚪  退出脚本"
    echo ""
    blue "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "  👉 请选择操作 [1-5]: " choice

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
main\n' read -r -d '' -a paths <<< "$results"
                
                local j=1
                for file_path in "${paths[@]}"; do
                    index_path_map["$i.$j"]="$file_path"
                    echo "   ${CYAN}$j.${RESET} $file_path"
                    j=$((j + 1))
                done
                i=$((i + 1))
            done
            
            echo ""
            echo "选择恢复目标："
            echo "  ${CYAN}[1]${RESET} 原路返回（恢复到原始位置）"
            echo "  ${CYAN}[2]${RESET} 恢复到 ~/restore/ 目录"
            echo ""
            read -p "请选择 [1-2]: " target_type
            
            if [[ "$target_type" != "1" ]] && [[ "$target_type" != "2" ]]; then
                red "✗ 无效输入"
                return 1
            fi
            
            echo ""
            read -p "输入要恢复的文件编号（格式: 日期编号.文件编号，多个用逗号分隔）: " file_indices
            
            if [ -z "$file_indices" ]; then
                yellow "操作已取消"
                return 0
            fi
            
            # 解析并恢复文件
            IFS=',' read -r -a pairs <<< "$file_indices"
            local success_count=0
            
            for pair in "${pairs[@]}"; do
                pair=$(echo "$pair" | xargs) # 去除空格
                local src_file="${index_path_map[$pair]}"
                
                if [ -z "$src_file" ]; then
                    yellow "⚠ 跳过无效编号: $pair"
                    continue
                fi
                
                if [ "$target_type" = "1" ]; then
                    # 原路返回
                    local user=$(whoami)
                    local target_path=${src_file#*${user}}
                    
                    if [ -d "$src_file" ]; then
                        target_path=${target_path%/*}
                    fi
                    
                    if cp -r "$src_file" "$HOME/$target_path" 2>/dev/null; then
                        green "✓ 已恢复: $src_file → $HOME/$target_path"
                        ((success_count++))
                    else
                        red "✗ 恢复失败: $src_file"
                    fi
                    
                elif [ "$target_type" = "2" ]; then
                    # 恢复到 restore 目录
                    local restore_dir="$HOME/restore"
                    mkdir -p "$restore_dir" 2>/dev/null
                    
                    if cp -r "$src_file" "$restore_dir/" 2>/dev/null; then
                        green "✓ 已恢复: $src_file → $restore_dir/"
                        ((success_count++))
                    else
                        red "✗ 恢复失败: $src_file"
                    fi
                fi
            done
            
            echo ""
            if [ $success_count -gt 0 ]; then
                green "✓ 成功恢复 $success_count 个文件/目录"
            else
                red "✗ 未能恢复任何文件"
            fi
            ;;
            
        0)
            return 0
            ;;
            
        *)
            red "✗ 无效选择"
            return 1
            ;;
    esac
}
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
    red "╔════════════════════════════════════════════════════════════╗"
    red "║                警  告 - 危险操作                           ║"
    red "╚════════════════════════════════════════════════════════════╝"
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
    blue "════════════════════════════════════════════════════════════"
    green "开始系统初始化..."
    log "=== System initialization started ==="
    blue "════════════════════════════════════════════════════════════"
    
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
    blue "════════════════════════════════════════════════════════════"
    green "✓ 系统初始化完成！"
    blue "════════════════════════════════════════════════════════════"
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
    echo ""
    echo -e "${CYAN}     ______            _                                      __  ${RESET}"
    echo -e "${CYAN}    / ____/___ _   __ (_)_____ ____   ____   ____ ___  ___  / /_ ${RESET}"
    echo -e "${CYAN}   / __/  / __  | / / / // ___// __  / / __  / / __  __ \/ _ \/ __/ ${RESET}"
    echo -e "${CYAN}  / /___ / / / / |/ / / // /   / /_/ // / / // / / / / / /  __/ / / /${RESET}"
    echo -e "${CYAN} /_____//_/ /_/|___//_//_/    \____//_/ /_//_/ /_/ /_/\___/_/ /_/ ${RESET}"
    echo ""
    yellow "                    📊 环境状态监控面板"
    blue   "                    ━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
        
    green "  ┌────────────────────────────────────────────────────────────┐"
    echo "  │ 用户名称: $(whoami)"
    echo "  │ 主目录: $HOME"
    echo "  │ 当前路径: $(pwd)"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
    
    # 磁盘使用情况
    if command -v df &> /dev/null; then
        green "  ┌─[ 💾 磁盘使用 ]─────────────────────────────────────────────┐"
        df -h "$HOME" 2>/dev/null | awk 'NR==2 {print "  │ 已用: " $3 " / 总计: " $2 " (" $5 ")                     │"}'
        green "  └────────────────────────────────────────────────────────────┘"
    fi
    echo ""
    
    # Cron 任务数量
    green "  ┌─[ ⏰ 定时任务 ]─────────────────────────────────────────────┐"
    local cron_count=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^

# 显示启动横幅
show_banner() {
    clear
    echo ""
    blue "╔════════════════════════════════════════════════════════════╗"
    blue "║          serv00 系统清理脚本 - SSH 管理面板               ║"
    blue "║                   精简增强版 v2.0                          ║"
    blue "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# 显示菜单
show_menu() {
    show_banner
    echo "  ${CYAN}[1]${RESET} 🗑️  初始化系统（清理数据）"
    echo "  ${CYAN}[2]${RESET} ⏰  仅清理 cron 任务"
    echo "  ${CYAN}[3]${RESET} 🔄  仅清理用户进程"
    echo "  ${CYAN}[4]${RESET} 📊  查看环境信息"
    echo "  ${CYAN}[5]${RESET} 💾  快照恢复系统"
    echo "  ${CYAN}[6]${RESET} 🚪  退出"
    echo ""
    blue "════════════════════════════════════════════════════════════"
    echo ""
    read -p "请选择操作 [1-6]: " choice

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
main | wc -l)
    echo "  │ Cron 任务数: $cron_count                                        │"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
    
    # 用户进程数
    green "  ┌─[ 🔄 进程统计 ]─────────────────────────────────────────────┐"
    local proc_count=$(ps -u $(whoami) 2>/dev/null | wc -l)
    echo "  │ 用户进程数: $proc_count                                         │"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
    
    # 主目录文件统计
    green "  ┌─[ 📁 文件统计 ]─────────────────────────────────────────────┐"
    local file_count=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    local dir_count=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo "  │ 文件数: $file_count                                             │"
    echo "  │ 目录数: $dir_count                                              │"
    green "  └────────────────────────────────────────────────────────────┘"
    echo ""
}

# 显示启动横幅
show_banner() {
    clear
    echo ""
    cyan '     _____           __               ____                 __  '
    cyan '    / ___/__  _____ / /____  ____ _  / __ \___  ________  / /_ '
    cyan '    \__ \/ / / / __ `/ __/ / / __ `/ / /_/ / _ \/ ___/ _ \/ __/ '
    cyan '   ___/ / /_/ / /_/ / /_/ /_/ /_/ / / _, _/  __(__  )  __/ /_   '
    cyan '  /____/\__, /\__,_/\__/\__/\__,_/ /_/ |_|\___/____/\___/\__/   '
    cyan '       /____/                                                    '
    echo ""
    yellow "           serv00 System Reset Script - Enhanced v2.0"
    blue   "           ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 显示菜单
show_menu() {
    show_banner
    green "  ╔════════════════════════════════════════════════════════════╗"
    green "  ║                       主 菜 单                             ║"
    green "  ╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "    ${CYAN}[1]${RESET} 🗑️  初始化系统 ${YELLOW}(清理所有数据)${RESET}"
    echo "    ${CYAN}[2]${RESET} ⏰  清理 Cron 任务"
    echo "    ${CYAN}[3]${RESET} 🔄  清理用户进程"
    echo "    ${CYAN}[4]${RESET} 📊  查看环境信息"
    echo "    ${CYAN}[5]${RESET} 🚪  退出脚本"
    echo ""
    blue "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "  👉 请选择操作 [1-5]: " choice

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
