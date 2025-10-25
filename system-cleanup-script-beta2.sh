#!/bin/bash

# ============================================================
# serv00 系统重置脚本（专业版）
# 版本: 3.0
# 适配环境: FreeBSD / Linux (serv00.com)
# 功能: 清理用户目录、终止进程、重置结构、清理定时任务、展示系统信息
# 说明: 彩色输出与图形化菜单用于提高可读性；语言为专业管理员风格。
# ============================================================

set -o pipefail
shopt -s nullglob dotglob 2>/dev/null || true

# === 颜色定义（保留 v3.0 霓虹配色） ===
NEON_PURPLE='\033[38;5;129m'
NEON_CYAN='\033[38;5;51m'
NEON_PINK='\033[38;5;201m'
NEON_GREEN='\033[38;5;46m'
NEON_YELLOW='\033[38;5;226m'
NEON_RED='\033[38;5;196m'
RESET='\033[0m'

# 检测终端是否支持颜色输出
if [ -t 1 ]; then
    USE_COLOR=1
else
    USE_COLOR=0
fi

# 彩色输出函数（自动降级）
color() {
    local code="$1"; shift
    if [ "$USE_COLOR" = 1 ]; then
        echo -e "${code}$*${RESET}"
    else
        echo "$*"
    fi
}
purple() { color "$NEON_PURPLE" "$*"; }
cyan()   { color "$NEON_CYAN" "$*"; }
pink()   { color "$NEON_PINK" "$*"; }
green()  { color "$NEON_GREEN" "$*"; }
yellow() { color "$NEON_YELLOW" "$*"; }
red()    { color "$NEON_RED" "$*"; }

# === 配置区 ===
LOG_FILE="$HOME/system_cleanup_$(date +%Y%m%d_%H%M%S).log"
SCRIPT_PID=$$
USERNAME=$(whoami)

# === 日志函数 ===
log() {
    # 将关键操作写入日志（若不可写则忽略）
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true
}

# === 环境检查 ===
check_env() {
    for cmd in whoami crontab pkill ps rm mkdir chmod uname uptime; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            red "错误: 缺少必要命令 $cmd"
            exit 1
        fi
    done
}

# === 系统信息模块（CPU / 内存 / 运行时间 / 负载） ===
print_system_info() {
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                      系统信息概览                           │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""

    # OS / Kernel
    os_info="$(uname -srm 2>/dev/null || echo "Unknown")"
    echo "操作系统 / 内核: $os_info"

    # Uptime
    if command -v uptime >/dev/null 2>&1; then
        uptime_info="$(uptime -p 2>/dev/null || uptime 2>/dev/null)"
        echo "运行时间: $uptime_info"
    fi

    # Load averages
    if command -v uptime >/dev/null 2>&1; then
        loads=$(uptime 2>/dev/null | awk -F'load averages?: ' '{print $2}' 2>/dev/null)
        [ -z "$loads" ] && loads=$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}' 2>/dev/null)
        [ -n "$loads" ] && echo "负载平均 (1/5/15m): $loads"
    fi

    # Memory (Linux: free -h; FreeBSD: sysctl hw.physmem + swapinfo if available)
    mem_info=""
    if command -v free >/dev/null 2>&1; then
        mem_info=$(free -h 2>/dev/null | awk 'NR==2{print $3 " / " $2 " (" $3"/"$2 ")"}')
        echo "内存使用: $mem_info"
    elif command -v sysctl >/dev/null 2>&1; then
        # FreeBSD fallback
        physmem_bytes=$(sysctl -n hw.physmem 2>/dev/null || true)
        if [[ "$physmem_bytes" =~ ^[0-9]+$ ]]; then
            # humanize bytes
            human_mem() {
                local b=$1
                local unit=("B" "K" "M" "G" "T")
                local i=0
                while [ "$b" -ge 1024 ] && [ $i -lt 4 ]; do
                    b=$((b/1024))
                    i=$((i+1))
                done
                printf "%s%s\n" "$b" "${unit[$i]}"
            }
            physmem_human=$(human_mem "$physmem_bytes")
            echo "物理内存(总计，近似): $physmem_human"
        fi
    fi

    # CPU info (model on Linux; basic on FreeBSD)
    if command -v lscpu >/dev/null 2>&1; then
        cpu_model=$(lscpu 2>/dev/null | awk -F: '/Model name|Model name/ {print $2; exit}' | sed 's/^[ \t]*//')
        cpu_cores=$(lscpu 2>/dev/null | awk -F: '/^CPU\\(s\\)|CPU\\(s\\)/ {print $2; exit}' | sed 's/^[ \t]*//')
        [ -n "$cpu_model" ] && echo "CPU: ${cpu_model} (${cpu_cores:-?} cores)"
    else
        # fallback
        echo "CPU: $(uname -p 2>/dev/null || echo "Unknown")"
    fi

    echo ""
}

# === 清空定时任务 ===
clean_cron() {
    log "清理 cron 任务"
    # Try to remove crontab for current user
    if crontab -r 2>/dev/null; then
        green "cron 任务已清空"
        log "Cron 任务已清理"
    else
        # if crontab -r failed, check if any tasks exist
        if crontab -l >/dev/null 2>&1; then
            yellow "清理失败（可能是权限问题）"
            log "清理 cron 任务失败"
        else
            green "无 cron 任务，跳过"
            log "未发现 cron 任务"
        fi
    fi
}

# === 终止当前用户的所有进程（排除自身） ===
kill_user_proc() {
    local user
    user=$(whoami)
    log "清理用户进程 (排除 PID: $SCRIPT_PID)"
    local count=0

    # Get PIDs owned by user, exclude the script PID and empty lines
    # Use ps compatible across Linux/FreeBSD
    for pid in $(ps -U "$user" -o pid= 2>/dev/null); do
        pid=$(echo "$pid" | tr -d '[:space:]')
        [[ -z "$pid" || "$pid" == "$SCRIPT_PID" ]] && continue
        # Double-check PID is numeric
        if [[ "$pid" =~ ^[0-9]+$ ]]; then
            if kill -9 "$pid" 2>/dev/null; then
                ((count++))
            fi
        fi
    done

    if [ "$count" -eq 0 ]; then
        yellow "未发现可终止的进程"
    else
        green "已终止 $count 个进程"
    fi
    log "已终止 $count 个进程"
}

# === 安全删除目录 ===
clean_directory() {
    local dir="$1"
    if [ -z "$dir" ]; then
        return 0
    fi
    if [ ! -d "$dir" ]; then
        return 0
    fi
    if rm -rf "$dir" 2>/dev/null; then
        green "已删除: $dir"
        log "已删除: $dir"
    else
        yellow "无法删除: $dir"
        log "删除失败: $dir"
    fi
}

# === 恢复默认文件结构 ===
restore_defaults() {
    local username
    username=$(whoami)
    log "恢复默认目录结构"

    cyan "创建基础目录..."
    mkdir -p "$HOME/mail" "$HOME/repo" && chmod 755 "$HOME/mail" "$HOME/repo"
    green "已创建 ~/mail 与 ~/repo"

    local domain_base="$HOME/domains/$username.serv00.net"
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access"
    chmod -R 755 "$domain_base"

    cat > "$domain_base/public_html/index.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>default.site</title>
    <meta charset="utf-8">
    <style>
        body { background: #1e1e1e; color: #00c8ff; font-family: 'Courier New', monospace; text-align: center; padding: 50px; margin: 0; }
        .container { border: 1px solid #00c8ff; padding: 30px; border-radius: 8px; max-width: 600px; margin: 0 auto; }
        h1 { font-size: 2em; margin-bottom: 15px; }
        p { font-size: 1em; opacity: 0.9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>默认站点已创建</h1>
        <p>欢迎访问本服务器</p>
        <p>服务器运行正常。</p>
    </div>
</body>
</html>
EOF

    chmod 644 "$domain_base/public_html/index.html" 2>/dev/null || true
    green "默认网站页面已生成"
    log "创建默认 index.html"
    green "默认结构恢复完成"
}

# === 初始化系统重置流程 ===
init_server() {
    clear
    red "============================================================"
    red "警告：此操作将清空用户目录和进程，且不可撤销。"
    red "============================================================"
    echo ""
    yellow "执行后将进行以下操作："
    echo "  • 清空所有定时任务 (cron)"
    echo "  • 终止当前用户的全部进程"
    echo "  • 删除用户目录下的内容"
    echo ""
    cyan "serv00 系统会自动保留最近 7 天备份（可在面板中恢复）"
    echo ""

    read -p "$(red '是否继续执行系统重置？[y/N]: ')" input
    input=${input:-N}
    if [[ ! "$input" =~ ^[Yy]$ ]]; then
        yellow "操作已取消。"
        log "用户取消操作"
        return 0
    fi

    echo ""
    read -p "$(cyan '是否保留配置文件 (.bashrc, .ssh 等)? [Y/n]: ')" saveProfile
    saveProfile=${saveProfile:-Y}

    cyan "开始执行系统重置流程..."
    log "=== 开始系统重置 ==="

    # 1. Cron
    echo ""; cyan "[1/5] 清理 cron 任务..."; clean_cron

    # 2. 缓存目录
    echo ""; cyan "[2/5] 清理缓存目录..."
    for d in go .cache .npm .yarn .cargo/registry .local/share/Trash; do
        [ -d "$HOME/$d" ] && clean_directory "$HOME/$d"
    done

    # 3. 主目录清理
    echo ""; cyan "[3/5] 清理主目录..."
    if [[ "$saveProfile" =~ ^[Yy]$ ]]; then
        green "保留模式：保留隐藏配置文件"
        rm -rf "$HOME"/* 2>/dev/null || true
        green "已清理非隐藏文件"
        log "清理非隐藏文件"
    else
        yellow "完全清理模式：包括隐藏文件"
        # 删除除日志文件外的所有项
        for item in "$HOME"/* "$HOME"/.*; do
            case "$item" in
                "$HOME/."|"$HOME/.."|"$LOG_FILE") continue ;;
            esac
            [ -e "$item" ] && rm -rf "$item" 2>/dev/null || true
        done
        green "已完全清空主目录"
        log "完全清空主目录"
    fi

    # 4. 恢复默认
    echo ""; cyan "[4/5] 恢复默认结构..."; restore_defaults

    # 5. 终止进程（最后）
    echo ""; cyan "[5/5] 终止用户进程..."
    yellow "SSH 连接可能在 3 秒内断开..."
    sleep 1 && echo -n "3..." && sleep 1 && echo -n "2..." && sleep 1 && echo "1..."
    kill_user_proc

    cyan "系统重置完成。"
    log "=== 系统重置完成 ==="
    echo ""
    green "默认网站: https://$USERNAME.serv00.net"
    [ -f "$LOG_FILE" ] && echo "日志文件: $LOG_FILE"
    echo ""
}

# === 系统状态显示 ===
show_info() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                      系统状态报告                           │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "用户: $(whoami)"
    echo "主目录: $HOME"
    echo "当前路径: $(pwd)"
    echo ""
    if command -v df >/dev/null 2>&1; then
        disk=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
        echo "磁盘使用: $disk"
    fi
    cron_n=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
    proc_n=$(ps -U "$(whoami)" 2>/dev/null | wc -l)
    file_n=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    dir_n=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo ""
    echo "统计信息:"
    echo "  Cron 任务数: $cron_n"
    echo "  进程数: $proc_n"
    echo "  文件数: $file_n"
    echo "  目录数: $dir_n"
    echo ""
}

# === 主菜单界面（保留图形化边框 + 霓虹配色与 emoji） ===
show_menu() {
    clear
    purple "┌────────────────────────────────────────────────────────────┐"
    purple "│                      serv00 系统重置工具 v3.0               │"
    purple "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  $(pink "1.") $(cyan "🔁 执行完整系统重置")"
    echo "  $(pink "2.") $(cyan "🕒 清空 cron 定时任务")"
    echo "  $(pink "3.") $(cyan "💀 终止用户进程")"
    echo "  $(pink "4.") $(cyan "📊 查看系统状态")"
    echo "  $(pink "5.") $(cyan "🚪 退出")"
    echo ""
    read -p "$(pink "请选择操作 [1-5]: ")" choice

    case $choice in
        1) init_server ;;
        2) clean_cron ;;
        3)
            yellow "此操作将终止全部用户进程 (SSH 可能断开)"
            read -p "$(red "确认执行？[y/N]: ")" c
            if [[ "$c" =~ ^[Yy]$ ]]; then
                sleep 2
                kill_user_proc
            else
                yellow "操作已取消"
            fi
            ;;
        4) show_info ;;
        5)
            read -p "$(yellow "确定退出？[Y/n]: ")" e
            if [[ ! "$e" =~ ^[Nn]$ ]]; then
                green "会话结束"
                exit 0
            fi
            ;;
        *) red "无效选项"; sleep 1 ;;
    esac
}

# === 信号处理 ===
trap 'log "用户中断脚本执行"; red "脚本被中断"; exit 130' INT TERM

# === 主程序入口 ===
main() {
    check_env
    log "=== 脚本启动，执行用户: $(whoami) ==="
    # 在主菜单前打印系统信息（顶部信息模块）
    print_system_info
    while true; do
        show_menu
        echo ""
        read -p "$(cyan "按 ENTER 返回主菜单...")" -r
    done
}

# 启动
main
