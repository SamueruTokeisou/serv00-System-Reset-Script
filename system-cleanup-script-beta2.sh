#!/bin/bash

# =============================================================================
# serv00 系统重置脚本 - 专业版
# 版本: 4.1
# 说明: 为serv00用户设计的高性能、高可靠性系统重置工具
# 功能: 系统清理、快照恢复、环境监控、日志审计
# 注意: 本脚本在用户权限下运行，不会执行需要root权限的操作
# =============================================================================

set -o pipefail
set -o errexit
set -o nounset

# =============================================================================
# 全局配置
# =============================================================================
readonly SCRIPT_VERSION="4.1"
readonly SCRIPT_NAME="serv00-reset"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly LOG_FILE="$HOME/${SCRIPT_NAME}_${TIMESTAMP}.log"
readonly BACKUP_PATH="$HOME/backups/local"
readonly SCRIPT_PID=$$
readonly MAX_RETRY=3

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# =============================================================================
# 工具函数
# =============================================================================

# 彩色输出函数
print_error() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $1" >&2
    log "[ERROR] $1"
}

print_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${RESET} $1"
    log "[WARNING] $1"
}

print_info() {
    echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"
    log "[INFO] $1"
}

print_step() {
    echo -e "${CYAN}${BOLD}[STEP]${RESET} $1"
}

print_title() {
    echo -e "${PURPLE}${BOLD}$1${RESET}"
}

# 日志记录
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$$] $1" >> "$LOG_FILE" 2>/dev/null || true
}

# 安全检查
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        print_error "缺少必要命令: $cmd"
        exit 1
    fi
}

# 环境检查
check_env() {
    print_info "开始环境检查..."
    
    # 检查必要命令
    local required_commands=(
        "whoami" "crontab" "pkill" "rm" "rsync" "find" 
        "df" "ps" "ls" "mkdir" "chmod" "grep" "awk"
    )
    
    for cmd in "${required_commands[@]}"; do
        check_command "$cmd"
    done
    
    # 检查权限
    if [ ! -w "$HOME" ]; then
        print_error "主目录无写权限: $HOME"
        exit 1
    fi
    
    print_success "环境检查完成"
}

# 确认对话
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    read -p "$(print_warning "$message [y/N] [$default]: " 2>&1)" input
    input=${input:-$default}
    
    if [[ "$input" =~ ^[Yy]$ ]]; then
        return 0
    else
        print_info "操作已取消"
        return 1
    fi
}

# 重试执行函数
retry_execute() {
    local max_attempts="$1"
    shift
    local cmd=("$@")
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if "${cmd[@]}" 2>/dev/null; then
            return 0
        else
            print_warning "命令执行失败 (尝试 $attempt/$max_attempts): ${cmd[*]}"
            ((attempt++))
            sleep 1
        fi
    done
    
    print_error "命令执行失败，已达到最大重试次数: ${cmd[*]}"
    return 1
}

# 安全地结束用户进程（保护脚本自身）- 参考脚本的改进
kill_user_processes() {
    print_step "清理用户进程..."
    log "开始清理用户进程 (保护脚本 PID: $SCRIPT_PID)"
    
    local user=$(whoami)
    local processes=$(ps -u "$user" -o pid= 2>/dev/null | grep -v "^[[:space:]]*$SCRIPT_PID$" || true)
    
    if [ -z "$processes" ]; then
        print_warning "⚠ 未找到需要清理的进程"
        log "未找到需要清理的进程"
        return 0
    fi
    
    local count=0
    for pid in $processes; do
        # 先尝试优雅终止
        if kill -TERM "$pid" 2>/dev/null; then
            sleep 0.1
            # 检查进程是否仍然存在
            if kill -0 "$pid" 2>/dev/null; then
                # 强制终止
                kill -9 "$pid" 2>/dev/null || true
            fi
            ((count++))
        fi
    done
    
    print_success "✓ 已清理 $count 个用户进程"
    log "已终止 $count 个进程"
}

# =============================================================================
# 核心功能函数
# =============================================================================

# 清理 cron 任务
clean_cron() {
    print_step "清理 cron 任务..."
    log "开始清理 cron 任务"
    
    local temp_cron=$(mktemp 2>/dev/null) || {
        print_error "无法创建临时文件"
        return 1
    }
    
    # 创建空的 crontab
    if crontab "$temp_cron" 2>/dev/null; then
        print_success "✓ cron 任务已清理"
        log "Cron 任务清理成功"
    else
        print_warning "⚠ 清理 cron 任务失败（可能没有任务）"
        log "Cron 任务清理失败"
    fi
    
    rm -f "$temp_cron" 2>/dev/null || true
}

# 清理特定目录
clean_directory() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        log "目录不存在，跳过: $dir"
        return 0
    fi
    
    # 尝试修改权限
    chmod -R 755 "$dir" 2>/dev/null || true
    
    if retry_execute 3 rm -rf "$dir"; then
        print_success "✓ 已删除: $dir"
        log "已删除目录: $dir"
    else
        print_warning "⚠ 无法删除: $dir"
        log "删除目录失败: $dir"
    fi
}

# 恢复 Web 默认设置
restore_web_defaults() {
    print_step "恢复 Web 默认设置..."
    log "开始恢复 Web 默认设置"
    
    local username=$(whoami)
    local domain_dir="$HOME/domains/$username.serv00.net/public_html"
    local access_log_dir="$HOME/domains/$username.serv00.net/logs/access"
    local index_file="$domain_dir/index.html"
    
    # 创建目录
    mkdir -p "$domain_dir" 2>/dev/null || true
    chmod 755 "$domain_dir" 2>/dev/null || true
    
    mkdir -p "$access_log_dir" 2>/dev/null || true
    chmod 755 "$access_log_dir" 2>/dev/null || true
    
    # 创建默认 index.html
    cat > "$index_file" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$username.serv00.net</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 40px;
            background-color: #f5f5f5;
            text-align: center;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>欢迎访问 $username.serv00.net</h1>
        <p>这是一个默认页面，表示您的网站配置已成功恢复。</p>
        <p>您可以开始部署您的网站内容了。</p>
    </div>
</body>
</html>
EOF
    
    chmod 644 "$index_file" 2>/dev/null || true
    
    print_success "✓ 已恢复 Web 默认设置"
    log "Web 默认设置恢复完成: $index_file 和 $access_log_dir"
}

# 系统初始化
system_init() {
    clear
    print_title "╔════════════════════════════════════════════════════════╗"
    print_title "║              警  告 - 危险操作                        ║"
    print_title "╚════════════════════════════════════════════════════════╝"
    echo ""
    print_warning "此操作将："
    echo "  • 清空所有 cron 定时任务"
    echo "  • 终止所有用户进程"
    echo "  • 删除主目录中的大部分文件"
    echo "  • 恢复 Web 默认设置"
    echo ""
    print_info "提示: serv00 自动保留最近 7 天的备份"
    echo ""
    
    if ! confirm_action "确定要初始化系统吗？这将删除大部分数据。"; then
        return 0
    fi
    
    echo ""
    read -p "$(print_info "是否保留用户配置文件（如 .bashrc, .ssh, .profile）？[Y/n]: " 2>&1)" saveProfile
    saveProfile=${saveProfile:-y}
    
    echo ""
    print_title "════════════════════════════════════════════════════════"
    print_success "开始系统初始化..."
    log "=== 系统初始化开始 ==="
    print_title "════════════════════════════════════════════════════════"
    
    # 步骤1: 清理 cron 任务
    echo ""
    print_step "[1/5] 清理 cron 定时任务"
    clean_cron
    
    # 步骤2: 清理特殊目录
    echo ""
    print_step "[2/5] 清理特殊目录"
    
    # 清理 Go 相关
    if [ -d "$HOME/go" ]; then
        clean_directory "$HOME/go"
    fi
    
    # 清理常见缓存目录
    local cache_dirs=(
        ".cache" ".npm" ".yarn" ".cargo/registry" 
        ".local/share/Trash" ".config" ".node-gyp"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "$HOME/$cache_dir" ]; then
            clean_directory "$HOME/$cache_dir"
        fi
    done
    
    # 步骤3: 清理主目录
    echo ""
    print_step "[3/5] 清理主目录文件"
    
    if [[ "$saveProfile" =~ ^[Yy]$ ]]; then
        print_success "→ 保留隐藏配置文件模式"
        log "保留隐藏配置文件模式"
        
        # 删除非隐藏文件和目录
        local items=("$HOME"/*)
        if [ -e "${items[0]}" ]; then
            for item in "${items[@]}"; do
                if [ -e "$item" ]; then
                    if retry_execute 3 rm -rf "$item"; then
                        log "已删除: $item"
                    else
                        print_warning "⚠ 无法删除: $item"
                    fi
                fi
            done
        fi
        
        print_success "✓ 已清理非隐藏文件（保留配置）"
        log "非隐藏文件清理完成"
    else
        print_warning "→ 完全清理模式（包括隐藏文件）"
        log "完全清理模式"
        
        # 删除所有文件（保护日志，保留 domains, mail, repo）
        local items=("$HOME"/{*,.[^.]*})
        for item in "${items[@]}"; do
            if [ -e "$item" ] && [ "$item" != "$HOME/." ] && [ "$item" != "$HOME/.." ] \
               && [ "$item" != "$LOG_FILE" ] && [ "$item" != "$HOME/domains" ] \
               && [ "$item" != "$HOME/mail" ] && [ "$item" != "$HOME/repo" ]; then
                if retry_execute 3 rm -rf "$item"; then
                    log "已删除: $item"
                else
                    print_warning "⚠ 无法删除: $item"
                fi
            fi
        done
        
        print_success "✓ 已完全清理主目录"
        log "完全清理主目录完成"
        
        # 清理后创建 mail 和 repo 目录
        for dir in "mail" "repo"; do
            if [ ! -d "$HOME/$dir" ]; then
                if mkdir -p "$HOME/$dir" && chmod 755 "$HOME/$dir"; then
                    print_success "✓ 创建 $HOME/$dir 目录"
                    log "创建目录: $HOME/$dir"
                fi
            fi
        done
    fi
    
    # 步骤4: 清理进程（最后执行）
    echo ""
    print_step "[4/5] 清理用户进程"
    print_warning "注意: 此操作将在 3 秒后执行，可能会断开 SSH 连接"
    sleep 1 && echo -n "3..." && sleep 1 && echo -n "2..." && sleep 1 && echo "1..."
    kill_user_processes
    
    # 步骤5: 恢复 Web 默认设置
    echo ""
    print_step "[5/5] 恢复 Web 默认设置"
    restore_web_defaults
    
    echo ""
    print_title "════════════════════════════════════════════════════════"
    print_success "✓ 系统初始化完成！"
    print_title "════════════════════════════════════════════════════════"
    log "=== 系统初始化完成 ==="
    
    echo ""
    print_info "提示："
    echo "  • serv00 自动保留最近 7 天的备份"
    echo "  • 如需恢复，请联系 serv00 管理面板"
    echo "  • 操作日志: $LOG_FILE"
    echo ""
}

# 快照恢复功能 - 参考脚本的改进版本
snapshot_recovery() {
    print_info "开始快照恢复功能..."
    
    if [ ! -d "$BACKUP_PATH" ]; then
        print_warning "未找到快照目录: $BACKUP_PATH"
        log "快照目录不存在: $BACKUP_PATH"
        return 1
    fi
    
    cd "$BACKUP_PATH"
    declare -A snapshot_paths
    
    # 读取快照链接 - 参考脚本的改进方式
    while read -r line; do
        if [[ $line =~ lrwxr ]]; then
            folder=$(echo "$line" | awk '{print $9}')
            real_path=$(echo "$line" | awk '{print $11}')
            if [ -n "$folder" ] && [ -n "$real_path" ]; then
                snapshot_paths["$folder"]="$real_path"
            fi
        fi
    done < <(ls -trl 2>/dev/null | grep -F "lrwxr" 2>/dev/null)
    
    local size=${#snapshot_paths[@]}
    local sorted_keys=($(printf '%s\n' "${!snapshot_paths[@]}" | sort -r))
    
    if [ $size -eq 0 ]; then
        print_warning "未有备份快照!"
        log "没有找到快照"
        return 1
    fi
    
    echo ""
    print_info "找到 $size 个快照"
    echo "选择你需要恢复的内容:"
    echo "1. 完整快照恢复"
    echo "2. 恢复某个文件或目录"
    read -p "$(print_info "请选择 [1-2]: " 2>&1)" input
    
    case "$input" in
        1)
            # 完整快照恢复
            echo ""
            print_info "可用快照列表:"
            local i=1
            declare -a folders
            for folder in "${sorted_keys[@]}"; do
                echo "${i}. ${folder}"
                folders+=("$folder")
                ((i++))
            done
            
            local retries=$MAX_RETRY
            while [ $retries -gt 0 ]; do
                read -p "$(print_info "请选择恢复到哪一天(序号): " 2>&1)" input
                if [[ $input =~ ^[0-9]+$ ]] && [ "$input" -gt 0 ] && [ "$input" -le $size ]; then
                    local targetFolder="${folders[$((input-1))]}"
                    print_success "你选择的恢复日期是：$targetFolder"
                    break
                else
                    ((retries--))
                    print_warning "输入有误，请重新输入！还剩 $retries 次机会。"
                fi
            done
            
            if [ $retries -eq 0 ]; then
                print_error "输入错误次数过多，操作已取消。"
                return 1
            fi
            
            if ! confirm_action "确认执行完整快照恢复？此操作不可逆！"; then
                return 0
            fi
            
            kill_user_processes
            local srcpath="${snapshot_paths["$targetFolder"]}"
            # 使用参考脚本的改进方式清理文件
            rm -rf ~/* >/dev/null 2>&1 || true
            rsync -a "$srcpath"/ ~/ 2>/dev/null || true
            print_success "快照恢复完成!"
            log "完整快照恢复完成: $targetFolder"
            ;;
        2)
            # 文件级恢复
            read -p "$(print_info "请输入要恢复的文件或目录名: " 2>&1)" infile
            if [ -z "$infile" ]; then
                print_info "输入为空，操作取消"
                return 0
            fi
            
            declare -A foundArr
            for folder in "${!snapshot_paths[@]}"; do
                local path="${snapshot_paths[$folder]}"
                local results=$(find "$path" -name "$infile" 2>/dev/null)
                if [[ -n "$results" ]]; then
                    foundArr["$folder"]="$results"
                fi
            done
            
            if [ ${#foundArr[@]} -eq 0 ]; then
                print_warning "在任何快照中都未找到文件: $infile"
                return 1
            fi
            
            local i=1
            local sortedFoundArr=($(printf '%s\n' "${!foundArr[@]}" | sort -r))
            declare -A indexPathArr
            
            for folder in "${sortedFoundArr[@]}"; do
                echo "$i. $folder:"
                local results="${foundArr[${folder}]}"
                # 使用参考脚本的改进方式处理多行结果
                IFS=$'\n' read -r -d '' -a paths <<<"$results"$'\n'
                local j=1
                for path in "${paths[@]}"; do
                    if [ -n "$path" ]; then
                        indexPathArr["$i.$j"]="$path"
                        echo "  $j. $path"
                        ((j++))
                    fi
                done
                ((i++))
            done
            
            while true; do
                read -p "$(print_info "输入要恢复的文件序号，格式:日期序号.文件序号, 多个以逗号分隔(如: 1.2,3.2)[按Enter返回]: " 2>&1)" input
                if [ -z "$input" ]; then
                    return 0
                fi
                
                local regex='^([0-9]+\.[0-9]+)(,[0-9]+\.[0-9]+)*$'
                if [[ "$input" =~ $regex ]]; then
                    IFS=',' read -r -a pairNos <<<"$input"
                    echo "请选择文件恢复的目标路径:"
                    echo "1. 原路返回"
                    echo "2. $HOME/restore"
                    read -p "$(print_info "请选择 [1-2]: " 2>&1)" targetDir
                    
                    case "$targetDir" in
                        1)
                            for pairNo in "${pairNos[@]}"; do
                                local srcpath="${indexPathArr[$pairNo]}"
                                if [ -n "$srcpath" ]; then
                                    local user=$(whoami)
                                    local targetPath="${srcpath#*${user}}"
                                    if [ -d "$srcpath" ]; then
                                        targetPath="${targetPath%/*}"
                                    fi
                                    # 参考脚本的路径处理方式
                                    mkdir -p "$HOME/${targetPath%/*}" 2>/dev/null || true
                                    cp -r "$srcpath" "$HOME/${targetPath}" 2>/dev/null || true
                                fi
                            done
                            ;;
                        2)
                            local targetPath="$HOME/restore"
                            mkdir -p "$targetPath" 2>/dev/null || true
                            for pairNo in "${pairNos[@]}"; do
                                local srcpath="${indexPathArr[$pairNo]}"
                                if [ -n "$srcpath" ]; then
                                    cp -r "$srcpath" "$targetPath/" 2>/dev/null || true
                                fi
                            done
                            ;;
                        *)
                            print_error "无效输入!"
                            continue
                            ;;
                    esac
                    
                    print_success "完成文件恢复"
                    log "文件恢复完成: $input"
                    break
                else
                    print_error "输入格式不对，请重新输入！"
                fi
            done
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
}

# 显示环境信息
show_system_info() {
    clear
    print_title "╔════════════════════════════════════════════════════════╗"
    print_title "║                  系统环境信息                          ║"
    print_title "╚════════════════════════════════════════════════════════╝"
    echo ""
    print_info "基本系统信息:"
    echo "  用户名称: $(whoami)"
    echo "  主目录: $HOME"
    echo "  当前路径: $(pwd)"
    echo "  脚本版本: $SCRIPT_VERSION"
    echo "  时间戳: $TIMESTAMP"
    echo ""
    
    # 磁盘使用情况
    if command -v df &> /dev/null; then
        print_info "磁盘使用情况:"
        df -h "$HOME" 2>/dev/null | awk 'NR==2 {print "  已用: " $3 " / 总计: " $2 " (" $5 ")"}'
    fi
    echo ""
    
    # Cron 任务数量
    local cron_count=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l 2>/dev/null)
    echo "  Cron 任务数: ${cron_count:-0}"
    
    # 用户进程数
    local proc_count=$(ps -u $(whoami) 2>/dev/null | wc -l 2>/dev/null)
    echo "  用户进程数: ${proc_count:-0}"
    echo ""
    
    # 主目录文件统计
    local file_count=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l 2>/dev/null)
    local dir_count=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l 2>/dev/null)
    echo "  主目录文件数: ${file_count:-0}"
    echo "  主目录目录数: ${dir_count:-0}"
    
    # 快照统计
    if [ -d "$BACKUP_PATH" ]; then
        local snapshot_count=$(ls -trl "$BACKUP_PATH" 2>/dev/null | grep -F "lrwxr" | wc -l 2>/dev/null)
        echo "  快照数量: ${snapshot_count:-0}"
    else
        echo "  快照数量: 0 (未找到快照目录)"
    fi
    
    echo ""
    print_info "系统资源信息:"
    if command -v free &> /dev/null; then
        free -h 2>/dev/null | head -n 2
    else
        echo "  (free 命令不可用，可能不支持内存信息)"
    fi
    
    echo ""
    print_title "════════════════════════════════════════════════════════"
    echo ""
    print_info "当前操作日志: $LOG_FILE"
}

# 显示启动横幅
show_banner() {
    clear
    print_title "╔════════════════════════════════════════════════════════════════════════════╗"
    echo -e "${GREEN}${BOLD}  ____            _   _                 ____                _   ${RESET}"
    echo -e "${GREEN}${BOLD} / ___| _   _ ___| |_(_)_ __ ___      |  _ \ ___  ___  ___| |_ ${RESET}"
    echo -e "${GREEN}${BOLD} \___ \| | | / __| __| | '\''_ \` _ \     | |_) / _ \/ __|/ _ \ __|${RESET}"
    echo -e "${GREEN}${BOLD}  ___) | |_| \__ \ |_| | | | | | |    |  _ <  __/\__ \  __/ |_ ${RESET}"
    echo -e "${GREEN}${BOLD} |____/ \__, |___/\__|_|_| |_| |_|    |_| \_\___||___/\___|\__|${RESET}"
    echo -e "${GREEN}${BOLD}        |___/                                                   ${RESET}"
    echo ""
    print_title "                 🚀 serv00 系统重置脚本 - 专业版 v$SCRIPT_VERSION"
    echo ""
    print_title "╚════════════════════════════════════════════════════════════════════════════╝"
}

# 显示菜单
show_menu() {
    show_banner
    echo ""
    print_title "═══════════════════════════[ 主菜单 ]══════════════════════════════"
    echo ""
    echo "  $(print_success '1.') 初始化系统（清理数据）"
    echo "  $(print_success '2.') 仅清理 cron 任务"
    echo "  $(print_success '3.') 仅清理用户进程"
    echo "  $(print_success '4.') 查看环境信息"
    echo "  $(print_success '5.') 快照恢复功能"
    echo "  $(print_success '6.') 退出"
    echo ""
    print_title "═══════════════════════════════════════════════════════════════════"
    echo ""
    read -p "$(print_info "请选择操作 [1-6]: " 2>&1)" choice

    case $choice in
        1) system_init ;;
        2)
            echo ""
            print_step "执行: 清理 cron 任务"
            clean_cron
            ;;
        3)
            echo ""
            print_warning "警告: 此操作将终止所有用户进程（可能断开连接）"
            if confirm_action "确认继续？"; then
                print_success "3 秒后执行..."
                sleep 3
                kill_user_processes
            fi
            ;;
        4) show_system_info ;;
        5) snapshot_recovery ;;
        6)
            if confirm_action "确认退出脚本？"; then
                print_success "退出脚本"
                log "脚本已退出"
                exit 0
            fi
            ;;
        *)
            print_error "无效的选择，请输入 1-6"
            sleep 1
            ;;
    esac
}

# 信号捕获
trap 'log "脚本被中断"; exit 130' INT TERM

# 主程序
main() {
    log "=== 脚本启动 (版本 $SCRIPT_VERSION) ==="
    
    check_env
    
    while true; do
        show_menu
        echo ""
        read -p "$(print_info "按 Enter 键继续..." 2>&1)" dummy
    done
}

# 启动
main "$@"



