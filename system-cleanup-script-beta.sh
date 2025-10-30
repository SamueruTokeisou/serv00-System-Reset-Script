#!/bin/bash

# serv00 系统重置脚本 - 自动版
# 版本: 4.3 Auto Edition
# 适配: FreeBSD (serv00.com)
# 作者: Tokeisou Samueru (自动版)

set -o pipefail

# === 颜色定义（精简版）===
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
RESET='\033[0m'

# 检测终端颜色支持
if [ -t 1 ]; then
    USE_COLOR=1
else
    USE_COLOR=0
fi

# === 彩色输出函数 ===
color() {
    local code="$1"; shift
    if [ "$USE_COLOR" = 1 ]; then
        echo -e "${code}$*${RESET}"
    else
        echo "$*"
    fi
}
purple() { color "$PURPLE" "$1"; }
cyan()   { color "$CYAN" "$1"; }
green()  { color "$GREEN" "$1"; }
yellow() { color "$YELLOW" "$1"; }
red()    { color "$RED" "$1"; }
blue()   { color "$BLUE" "$1"; }

# === 配置区 ===
SCRIPT_VERSION="4.3"
LOG_DIR="$HOME/.serv00_logs"
LOG_FILE="$LOG_DIR/reset_$(date +%Y%m%d_%H%M%S).log"
BACKUP_LIST="$LOG_DIR/backup_list.txt"
SCRIPT_PID=$$

# 创建日志目录
mkdir -p "$LOG_DIR" 2>/dev/null

# === 增强日志函数 ===
log() {
    local level="$1"; shift
    local msg="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$LOG_FILE" 2>/dev/null
}

log_info() { log "INFO" "$*"; }
log_warn() { log "WARN" "$*"; }
log_error() { log "ERROR" "$*"; }
log_success() { log "SUCCESS" "$*"; }

# === 进度条函数 ===
show_progress() {
    local current=$1
    local total=$2
    local text="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r  ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%% - %s" "$percent" "$text"
    
    [ "$current" -eq "$total" ] && echo ""
}

# === 环境检查（修复版）===
check_env() {
    local missing_cmds=()
    for cmd in whoami crontab ps rm mkdir chmod find df awk grep; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        red "❌ 错误: 缺少必要命令: ${missing_cmds[*]}"
        log_error "缺少命令: ${missing_cmds[*]}"
        exit 1
    fi
    
    # 检查是否在 serv00 环境（更严格的检查）
    if [[ ! "$HOME" =~ serv00 ]] && [[ ! -d "$HOME/domains" ]]; then
        yellow "⚠️  警告: 当前似乎不在 serv00 环境"
        read -p "是否继续？[y/N]: " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0
    fi
    
    # 检查是否有足够权限
    if [ ! -w "$HOME" ]; then
        red "❌ 错误: 没有写入主目录的权限"
        exit 1
    fi
}

# === 备份重要文件列表（修复版）===
create_backup_list() {
    log_info "创建备份清单"
    {
        echo "=== 重置前文件清单 ==="
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "用户: $(whoami)"
        echo "脚本版本: $SCRIPT_VERSION"
        echo ""
        echo "=== 系统信息 ==="
        echo "主目录: $HOME"
        echo "当前路径: $(pwd)"
        echo ""
        echo "=== Cron 任务 ==="
        if crontab -l 2>/dev/null; then
            crontab -l 2>/dev/null
        else
            echo "无 cron 任务"
        fi
        echo ""
        echo "=== 进程列表 ==="
        ps -U "$(whoami)" -o pid,ppid,cmd --no-headers 2>/dev/null || echo "无法获取进程列表"
        echo ""
        echo "=== 目录结构 ==="
        find "$HOME" -maxdepth 2 -type d 2>/dev/null | head -50
        echo ""
        echo "=== 磁盘使用 ==="
        df -h "$HOME" 2>/dev/null
        echo ""
        echo "=== 文件统计 ==="
        find "$HOME" -type f 2>/dev/null | wc -l | awk '{print "总文件数: " $1}'
        find "$HOME" -type d 2>/dev/null | wc -l | awk '{print "总目录数: " $1}'
    } > "$BACKUP_LIST" 2>/dev/null
    
    if [ -f "$BACKUP_LIST" ]; then
        blue "📋 备份清单已保存: $BACKUP_LIST"
        log_success "备份清单创建成功"
    fi
}

# === 清空 Cron 任务（修复版）===
clean_cron() {
    log_info "开始清理 cron 任务"
    
    # 先备份当前 cron
    local cron_backup="$LOG_DIR/cron_backup_$(date +%Y%m%d_%H%M%S).txt"
    if crontab -l > "$cron_backup" 2>/dev/null; then
        blue "  💾 已备份 cron 到: $cron_backup"
    else
        log_info "当前无 cron 任务"
    fi
    
    if crontab -r 2>/dev/null; then
        green "  ✅ cron 任务已清空"
        log_success "Cron 任务清理成功"
    else
        if crontab -l >/dev/null 2>&1; then
            yellow "  ⚠️  清理失败（权限问题）"
            log_warn "Cron 清理失败"
        else
            green "  ✅ 无 cron 任务"
            log_info "未发现 cron 任务"
        fi
    fi
}

# === 终止用户进程（修复版）===
kill_user_proc() {
    local user=$(whoami)
    log_info "开始清理用户进程 (排除 PID: $SCRIPT_PID)"
    
    local pids=()
    local count=0
    
    # 收集进程列表（使用更安全的方式，避免阻塞）
    local all_pids=$(ps -U "$user" -o pid= 2>/dev/null | grep -v "^$")
    if [ -z "$all_pids" ]; then
        yellow "  ⚠️  未发现可终止的进程"
        log_info "无可终止进程"
        return 0
    fi
    
    for pid in $all_pids; do
        [[ -z "$pid" || "$pid" == "$SCRIPT_PID" ]] && continue
        # 验证进程确实属于当前用户
        if ps -p "$pid" -o user= 2>/dev/null | grep -q "$user"; then
            pids+=("$pid")
        fi
    done
    
    local total=${#pids[@]}
    if [ "$total" -eq 0 ]; then
        yellow "  ⚠️  未发现可终止的进程"
        log_info "无可终止进程"
        return 0
    fi
    
    echo "  📊 发现 $total 个进程，开始清理..."
    
    for pid in "${pids[@]}"; do
        if kill -9 "$pid" 2>/dev/null; then
            ((count++))
            log_info "已终止进程 $pid"
        else
            log_warn "无法终止进程 $pid"
        fi
        # 不显示进度条，避免在FreeBSD上卡住
        echo -n "."
    done
    
    echo ""
    green "  ✅ 已终止 $count/$total 个进程"
    log_success "成功终止 $count 个进程"
}

# === 智能目录清理（修复版）===
clean_directory() {
    local dir="$1"
    local name="$2"
    
    if [ ! -d "$dir" ]; then
        return 0
    fi
    
    # 检查目录是否为空
    if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
        green "  ✅ $name 已为空，跳过"
        return 0
    fi
    
    local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    
    if rm -rf "$dir" 2>/dev/null; then
        green "  ✅ 已删除 $name ($size)"
        log_success "删除目录: $dir ($size)"
    else
        yellow "  ⚠️  无法删除 $name"
        log_warn "删除失败: $dir"
    fi
}

# === 恢复默认结构（修复版）===
restore_defaults() {
    local username=$(whoami)
    log_info "开始恢复默认目录结构"

    cyan "  🏗️  创建基础目录..."
    
    # 创建基础目录结构
    local base_dirs=("mail" "repo" "logs" "tmp")
    for dir in "${base_dirs[@]}"; do
        if [ ! -d "$HOME/$dir" ]; then
            mkdir -p "$HOME/$dir" && chmod 755 "$HOME/$dir"
            green "  ✅ 已创建 ~/$dir"
        else
            green "  ✅ ~/$dir 已存在"
        fi
    done

    # 创建域名目录结构
    local domain_base="$HOME/domains/$username.serv00.net"
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access" "$domain_base/cgi-bin"
    chmod -R 755 "$domain_base"

    # 创建默认首页
    cat > "$domain_base/public_html/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Serv00 Reset Complete</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        h1 {
            margin-top: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .status {
            background: rgba(0,255,0,0.2);
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>✅ 系统重置完成</h1>
        <div class="status">
            <h2>系统已就绪</h2>
            <p>您的 Serv00 服务器已重置</p>
        </div>
        <p>开始部署您的应用吧！</p>
    </div>
</body>
</html>
EOF

    chmod 644 "$domain_base/public_html/index.html"
    green "  ✅ 已创建默认首页"
    log_success "创建默认 index.html"

    # 创建基本的 .htaccess 文件
    cat > "$domain_base/public_html/.htaccess" <<'EOF'
# Serv00 基础配置
DirectoryIndex index.html index.php

# 安全设置
Options -Indexes
Options +FollowSymLinks

# 字符编码
AddDefaultCharset UTF-8

# 缓存设置
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
</IfModule>
EOF

    chmod 644 "$domain_base/public_html/.htaccess"
    green "  ✅ 已创建 .htaccess 配置文件"

    echo ""
    green "✅ 默认结构恢复完成"
    log_success "默认结构恢复完成"
}

# === 完整系统重置（自动版）===
init_server() {
    clear
    red "┌────────────────────────────────────────────────────────────┐"
    red "│                  ⚠️  危险操作警告 ⚠️                       │"
    red "│                此操作将不可撤销！                           │"
    red "└────────────────────────────────────────────────────────────┘"
    echo ""
    yellow "执行后将进行以下操作："
    echo "  • 🔥 清空所有定时任务 (cron)"
    echo "  • 💀 终止当前用户的全部进程"
    echo "  • 🧹 删除用户目录下的大部分内容"
    echo "  • 🏗️  恢复默认目录结构"
    echo ""
    cyan "💡 serv00 自动保留最近 7 天备份（可在面板中恢复）"
    blue "💾 操作前会自动创建文件清单备份"
    echo ""

    read -p "$(red '是否继续执行系统重置？[y/N]: ')" input
    input=${input:-N}
    if [[ ! "$input" =~ ^[Yy]$ ]]; then
        yellow "🛑 操作已取消"
        log_info "用户取消完整重置操作"
        return 0
    fi

    echo ""
    read -p "$(cyan '是否保留配置文件 (.bashrc, .ssh 等)? [Y/n]: ')" saveProfile
    saveProfile=${saveProfile:-Y}

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    purple() { color "$PURPLE" "$1"; }
    purple "🚀 启动系统重置协议 v$SCRIPT_VERSION"
    cyan "════════════════════════════════════════════════════════════"
    log_info "=== 开始完整系统重置 ==="

    # 0. 创建备份清单
    echo ""; cyan "[0/7] 📋 创建备份清单..."
    create_backup_list
    sleep 1

    # 1. 清理定时任务
    echo ""; cyan "[1/7] 🕒 清理 cron 任务..."
    clean_cron
    sleep 1

    # 2. 清理缓存目录
    echo ""; cyan "[2/7] 🧹 清理缓存目录..."
    local cache_dirs=("go" ".cache" ".npm" ".yarn" ".cargo" ".local/share/Trash" "tmp")
    local cleaned=0
    for d in "${cache_dirs[@]}"; do
        if [ -d "$HOME/$d" ]; then
            clean_directory "$HOME/$d" "$d"
            ((cleaned++))
        fi
    done
    green "  ✅ 已清理 $cleaned 个缓存目录"
    sleep 1

    # 3. 清理主目录
    echo ""; cyan "[3/7] 🗑️  清理主目录..."
    if [[ "$saveProfile" =~ ^[Yy]$ ]]; then
        green "  → 保留模式：保留隐藏配置文件"
        # 保留配置文件，删除其他文件
        find "$HOME" -maxdepth 1 -type f -not -path "$HOME/.serv00_logs/*" -not -name ".*" -delete 2>/dev/null
        find "$HOME" -maxdepth 1 -type d -not -name "." -not -name ".." -not -name ".serv00_logs" -not -name "mail" -not -name "repo" -not -name "domains" -exec rm -rf {} + 2>/dev/null
        green "  ✅ 已清理非配置文件和目录"
        log_info "清理非配置文件（保留模式）"
    else
        yellow "  → 完全清理模式：包括隐藏文件"
        local protected=("." ".." "$LOG_DIR")
        
        # 使用更安全的方式清空目录
        for item in "$HOME"/* "$HOME"/.*; do
            [[ ! -e "$item" ]] && continue  # 跳过不存在的文件
            local skip=0
            for p in "${protected[@]}"; do
                [[ "$item" == "$HOME/$p" ]] && { skip=1; break; }
            done
            [ "$skip" -eq 1 ] && continue
            rm -rf "$item" 2>/dev/null
        done
        
        green "  ✅ 已完全清空主目录"
        log_info "完全清空主目录"
    fi
    sleep 1

    # 4. 清理用户进程
    echo ""; cyan "[4/7] 💀 终止用户进程..."
    yellow "  ⚠️  SSH 连接可能在 3 秒内断开..."
    for i in 3 2 1; do
        echo -n "  $i..."
        sleep 1
    done
    echo ""
    kill_user_proc
    sleep 1

    # 5. 恢复默认结构
    echo ""; cyan "[5/7] 🏗️  恢复默认结构..."
    restore_defaults
    sleep 1

    # 6. 验证重置结果
    echo ""; cyan "[6/7] ✅ 验证重置结果..."
    local checks=0
    local total_checks=4
    
    if [ -d "$HOME/mail" ]; then ((checks++)); green "  ✅ mail 目录已创建"; else red "  ❌ mail 目录创建失败"; fi
    if [ -d "$HOME/repo" ]; then ((checks++)); green "  ✅ repo 目录已创建"; else red "  ❌ repo 目录创建失败"; fi
    if [ -d "$HOME/domains/$(whoami).serv00.net/public_html" ]; then ((checks++)); green "  ✅ 域名目录已创建"; else red "  ❌ 域名目录创建失败"; fi
    if [ -f "$HOME/domains/$(whoami).serv00.net/public_html/index.html" ]; then ((checks++)); green "  ✅ 首页文件已创建"; else red "  ❌ 首页文件创建失败"; fi
    
    green "  ✅ 验证完成: $checks/$total_checks 项通过"
    sleep 1

    # 7. 生成完成报告
    echo ""; cyan "[7/7] 📊 生成重置报告..."
    sleep 1

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    green "✅ 系统重置完成"
    cyan "════════════════════════════════════════════════════════════"
    log_success "=== 系统重置完成 ==="

    local username=$(whoami)
    echo ""
    blue "📌 重置后信息:"
    echo "  • 备份清单: $BACKUP_LIST"
    echo "  • 日志文件: $LOG_FILE"
    echo "  • 默认网站: https://$username.serv00.net"
    echo "  • serv00 备份: 面板中可恢复最近 7 天快照"
    echo ""
    blue "💡 提示: 使用选项 7 查看详细重置报告"
    echo ""
}

# === 选择性清理（自动版）===
selective_clean() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│              🎯 选择性清理模式                             │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    local options=(
        "缓存目录 (.cache, .npm, .yarn, .cargo)"
        "临时文件 (tmp, .tmp)"
        "日志文件 (*.log, logs/*)"
        "编程环境 (go, node_modules)"
        "下载目录 (Downloads)"
        "全部以上"
    )
    
    echo "选择要清理的项目（多选用空格分隔）:"
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}"
    done
    echo ""
    
    read -p "请输入选项 (如: 1 3 5): " choices
    
    if [[ "$choices" == *"6"* ]] || [[ "$choices" == *"全"* ]]; then
        choices="1 2 3 4 5"
    fi
    
    echo ""
    cyan "开始清理..."
    
    for choice in $choices; do
        case $choice in
            1)
                echo ""; blue "[1] 清理缓存目录..."
                clean_directory "$HOME/.cache" "缓存目录"
                clean_directory "$HOME/.npm" "NPM 缓存"
                clean_directory "$HOME/.yarn" "Yarn 缓存"
                clean_directory "$HOME/.cargo/registry" "Cargo 缓存"
                clean_directory "$HOME/.cargo/git" "Cargo Git 缓存"
                ;;
            2)
                echo ""; blue "[2] 清理临时文件..."
                clean_directory "$HOME/tmp" "临时目录"
                clean_directory "$HOME/.tmp" "隐藏临时目录"
                ;;
            3)
                echo ""; blue "[3] 清理日志文件..."
                find "$HOME" -name "*.log" -type f -delete 2>/dev/null
                clean_directory "$HOME/logs" "日志目录"
                ;;
            4)
                echo ""; blue "[4] 清理编程环境..."
                clean_directory "$HOME/go" "Go 环境"
                find "$HOME" -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null
                green "  ✅ node_modules 已清理"
                ;;
            5)
                echo ""; blue "[5] 清理下载目录..."
                clean_directory "$HOME/Downloads" "下载目录"
                rm -f "$HOME/.wget-hsts" 2>/dev/null
                green "  ✅ 下载相关文件已清理"
                ;;
        esac
    done
    
    echo ""
    green "✅ 选择性清理完成"
    log_success "选择性清理完成: $choices"
}

# === 查看重置报告（自动版）===
show_report() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                📊 系统重置报告                             │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    if [ ! -f "$LOG_FILE" ]; then
        yellow "暂无重置记录"
        return 0
    fi
    
    echo "📁 当前日志: $LOG_FILE"
    echo ""
    
    local total_logs=$(ls -1 "$LOG_DIR"/reset_*.log 2>/dev/null | wc -l)
    echo "📚 历史记录数: $total_logs"
    echo ""
    
    if [ -f "$BACKUP_LIST" ]; then
        echo "📋 备份清单预览:"
        head -20 "$BACKUP_LIST"
        if [ $(wc -l < "$BACKUP_LIST") -gt 20 ]; then
            echo "..."
            tail -5 "$BACKUP_LIST"
        fi
        echo ""
    fi
    
    echo "最近操作日志:"
    tail -20 "$LOG_FILE" 2>/dev/null || echo "无日志内容"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
}

# === 系统状态显示（自动版）===
show_info() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                🖥️  系统状态报告                            │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    local username=$(whoami)
    echo "👤 用户: $username"
    echo "🏠 主目录: $HOME"
    echo "📍 当前路径: $(pwd)"
    echo "⏰ 系统时间: $(date)"
    echo ""

    # 磁盘使用情况
    if command -v df >/dev/null; then
        local disk_info=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
        echo "💾 磁盘使用: $disk_info"
        
        local usage_percent=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
        if [ -n "$usage_percent" ] && [ "$usage_percent" -gt 80 ]; then
            red "   ⚠️  磁盘使用率超过 80%"
        elif [ -n "$usage_percent" ] && [ "$usage_percent" -gt 90 ]; then
            red "   🔴 磁盘使用率超过 90%，请注意！"
        fi
    fi

    # 统计信息
    local cron_n=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l | tr -d ' ')
    local proc_n=$(ps -U "$username" 2>/dev/null | wc -l | tr -d ' ')
    local file_n=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    local dir_n=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)

    echo ""
    echo "📊 资源统计:"
    printf "  %-20s %s\n" "Cron 任务:" "$cron_n 个"
    printf "  %-20s %s\n" "运行进程:" "$proc_n 个"
    printf "  %-20s %s\n" "根目录文件:" "$file_n 个"
    printf "  %-20s %s\n" "根目录子目录:" "$dir_n 个"
    
    # 检查关键目录
    echo ""
    echo "📁 关键目录状态:"
    for dir in "mail" "repo" "domains" ".ssh"; do
        if [ -d "$HOME/$dir" ]; then
            green "  ✅ ~/$dir"
        else
            yellow "  ⚠️  ~/$dir (不存在)"
        fi
    done
    
    # 网站状态
    if [ -d "$HOME/domains/$username.serv00.net/public_html" ]; then
        echo ""
        echo "🌐 默认网站:"
        local index_file="$HOME/domains/$username.serv00.net/public_html/index.html"
        if [ -f "$index_file" ]; then
            green "  ✅ https://$username.serv00.net"
            local size=$(du -sh "$index_file" 2>/dev/null | awk '{print $1}')
            echo "     首页大小: $size"
        else
            yellow "  ⚠️  首页文件不存在"
        fi
    fi
    
    # 最近重置记录
    if [ -f "$LOG_DIR/reset_*.log" ]; then
        local last_reset=$(ls -1t "$LOG_DIR"/reset_*.log 2>/dev/null | head -1 | sed 's/.*reset_\([0-9]*_[0-9]*\).log/\1/')
        if [ -n "$last_reset" ]; then
            echo ""
            blue "📋 最近重置: ${last_reset:0:8} ${last_reset:9:2}:${last_reset:11:2}"
        fi
    fi
    
    echo ""
    cyan "────────────────────────────────────────────────────────────"
}

# === 快速恢复功能（自动版）===
quick_restore() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│              ⚡ 快速恢复向导                               │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    yellow "此功能将快速恢复基本目录结构和默认网站"
    echo "不会删除现有文件，只创建缺失的目录和文件"
    echo ""
    
    read -p "$(cyan '是否继续？[Y/n]: ')" confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    echo ""
    cyan "开始快速恢复..."
    log_info "启动快速恢复"
    
    restore_defaults
    
    echo ""
    green "✅ 快速恢复完成！"
    log_success "快速恢复完成"
}

# === 清理历史日志（自动版）===
clean_old_logs() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│              🗑️  日志清理工具                              │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    local log_files=("$LOG_DIR"/reset_*.log)
    local log_count=${#log_files[@]}
    
    if [ "$log_count" -eq 0 ] || [ ! -f "${log_files[0]}" ]; then
        yellow "没有找到日志文件"
        return 0
    fi
    
    echo "📊 当前日志统计:"
    echo "  文件数量: $log_count"
    
    if command -v du >/dev/null; then
        local total_size=$(du -sh "$LOG_DIR" 2>/dev/null | awk '{print $1}')
        echo "  总大小: $total_size"
    fi
    
    echo ""
    yellow "选项:"
    echo "  1. 保留最近 5 个日志"
    echo "  2. 保留最近 10 个日志"
    echo "  3. 清空所有日志（除当前日志）"
    echo "  4. 取消"
    echo ""
    
    read -p "$(cyan '请选择 [1-4]: ')" choice
    
    case $choice in
        1|2)
            local keep=${choice}
            [ "$keep" -eq 1 ] && keep=5 || keep=10
            
            echo ""
            cyan "保留最近 $keep 个日志，删除其余..."
            
            # 使用更安全的方式排序和删除
            local sorted_logs=($(ls -tr "$LOG_DIR"/reset_*.log 2>/dev/null))
            local total_files=${#sorted_logs[@]}
            
            if [ $total_files -gt $keep ]; then
                local to_delete=$((total_files - keep))
                for ((i=0; i<to_delete; i++)); do
                    local file_to_delete="${sorted_logs[$i]}"
                    if [ "$file_to_delete" != "$LOG_FILE" ]; then
                        rm -f "$file_to_delete" 2>/dev/null
                        echo "  已删除: $(basename "$file_to_delete")"
                    fi
                done
                green "✅ 清理完成，保留 $keep 个日志"
            else
                yellow "日志数量少于 $keep，无需清理"
            fi
            log_success "清理旧日志（保留 $keep 个）"
            ;;
        3)
            echo ""
            red "⚠️  将删除所有日志文件（除当前日志）！"
            read -p "确认？[y/N]: " confirm
            
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                find "$LOG_DIR" -name "reset_*.log" -not -name "$(basename "$LOG_FILE")" -delete 2>/dev/null
                green "✅ 已清空旧日志（保留当前日志）"
                log_success "清空旧日志"
            else
                yellow "操作取消"
            fi
            ;;
        *)
            yellow "操作取消"
            ;;
    esac
}

# === 主菜单界面（自动版）===
show_menu() {
    clear
    echo ""
    purple "╔════════════════════════════════════════════════════════════╗"
    purple "║      🌐 Serv00 系统重置工具 v$SCRIPT_VERSION               ║"
    purple "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    echo "  $(purple "1.") $(cyan "🗑️   执行完整系统重置      ") $(red "[危险操作]")"
    echo "  $(purple "2.") $(cyan "🎯  选择性清理             ") $(green "[推荐]")"
    echo "  $(purple "3.") $(cyan "⚡  快速恢复默认结构       ") $(blue "[安全]")"
    echo ""
    echo "  $(purple "4.") $(cyan "🕒  清空 cron 定时任务    ")"
    echo "  $(purple "5.") $(cyan "💀  终止用户进程           ")"
    echo "  $(purple "6.") $(cyan "📊  查看系统状态           ")"
    echo ""
    echo "  $(purple "7.") $(cyan "📋  查看重置报告           ")"
    echo "  $(purple "8.") $(cyan "🗑️   清理历史日志          ")"
    echo "  $(purple "9.") $(cyan "🚪  退出                   ")"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
    
    # 显示系统状态摘要
    local username=$(whoami)
    local disk_usage=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
    local proc_count=$(ps -U "$username" 2>/dev/null | wc -l | tr -d ' ')
    
    echo "📋 系统摘要: 进程 $proc_count 个"
    if [ -n "$disk_usage" ] && [ "$disk_usage" -gt 0 ]; then
        echo "💾 磁盘使用: ${disk_usage}%"
        if [ "$disk_usage" -gt 80 ]; then
            echo "⚠️  磁盘使用率较高"
        fi
    fi
    
    echo ""
    read -p "$(purple ">> 请选择操作 [1-9]: ")" choice

    case $choice in
        1)
            init_server
            ;;
        2)
            selective_clean
            ;;
        3)
            quick_restore
            ;;
        4)
            echo ""
            cyan "执行中: 清理 cron 定时任务"
            clean_cron
            ;;
        5)
            echo ""
            yellow "⚠️  此操作将终止全部用户进程 (SSH 可能断开)"
            read -p "$(red "确认执行？[y/N]: ")" c
            
            if [[ "$c" =~ ^[Yy]$ ]]; then
                echo ""
                cyan "准备终止进程..."
                sleep 2
                kill_user_proc
            else
                yellow "操作取消"
            fi
            ;;
        6)
            show_info
            ;;
        7)
            show_report
            ;;
        8)
            clean_old_logs
            ;;
        9)
            echo ""
            read -p "$(yellow "确定退出？[Y/n]: ")" e
            e=${e:-Y}
            
            if [[ "$e" =~ ^[Yy]$ ]]; then
                green "🔌 感谢使用，再见！"
                log_info "用户正常退出"
                exit 0
            fi
            ;;
        *)
            red "❌ 无效选项，请输入 1-9"
            sleep 1
            ;;
    esac
}

# === 启动欢迎界面 ===
show_welcome() {
    clear
    echo ""
    purple "╔════════════════════════════════════════════════════════════╗"
    purple "║                                                            ║"
    purple "║          🚀 Serv00 系统重置工具 v$SCRIPT_VERSION           ║"
    purple "║                                                            ║"
    purple "╚════════════════════════════════════════════════════════════╝"
    echo ""
    cyan "  作者: Tokeisou Samueru"
    cyan "  适配: FreeBSD (serv00.com)"
    echo ""
    blue "  ✨ 功能特点:"
    echo "    • 安全的系统重置"
    echo "    • 选择性清理模式"
    echo "    • 自动备份与恢复"
    echo "    • 详细的日志记录"
    echo "    • 一键快速恢复"
    echo ""
    yellow "  ⚠️  使用说明:"
    echo "    • 推荐先使用选择性清理"
    echo "    • 完整重置前请确认重要数据已备份"
    echo "    • serv00 提供7天自动备份"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
    echo ""
    read -p "$(green "按 ENTER 进入主菜单...")" -r
}

# === 信号处理 ===
cleanup_on_exit() {
    log_info "脚本异常退出"
    echo ""
    yellow "⚠️  脚本被中断"
    exit 130
}

trap cleanup_on_exit INT TERM

# === 主程序入口 ===
main() {
    # 环境检查
    check_env
    
    # 记录启动
    log_info "=== 脚本启动 v$SCRIPT_VERSION ==="
    log_info "执行用户: $(whoami)"
    log_info "主目录: $HOME"
    log_info "脚本 PID: $SCRIPT_PID"
    
    # 显示欢迎界面（仅首次）
    if [ ! -f "$LOG_DIR/.welcomed" ]; then
        show_welcome
        touch "$LOG_DIR/.welcomed" 2>/dev/null
    fi
    
    # 主循环
    while true; do
        show_menu
        echo ""
        read -p "$(cyan "按 ENTER 返回主菜单...")" -r
    done
}

# 启动脚本
main "$@"
