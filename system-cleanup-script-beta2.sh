#!/bin/bash

# ============================================================
# serv00 系统重置脚本（全自动安全版）
# 版本: 3.1
# 适配环境: FreeBSD / Linux (serv00.com)
# 功能: 清理用户目录、终止进程、重置结构、清理定时任务、展示系统信息
# ============================================================

set -o pipefail
shopt -s nullglob dotglob 2>/dev/null || true

# === 颜色定义 ===
NEON_PURPLE='\033[38;5;129m'
NEON_CYAN='\033[38;5;51m'
NEON_PINK='\033[38;5;201m'
NEON_GREEN='\033[38;5;46m'
NEON_YELLOW='\033[38;5;226m'
NEON_RED='\033[38;5;196m'
RESET='\033[0m'

USE_COLOR=1
color() { [ "$USE_COLOR" = 1 ] && echo -e "${1}$2${RESET}" || echo "$2"; }
purple() { color "$NEON_PURPLE" "$*"; }
cyan()   { color "$NEON_CYAN" "$*"; }
pink()   { color "$NEON_PINK" "$*"; }
green()  { color "$NEON_GREEN" "$*"; }
yellow() { color "$NEON_YELLOW" "$*"; }
red()    { color "$NEON_RED" "$*"; }

LOG_FILE="$HOME/system_cleanup_$(date +%Y%m%d_%H%M%S).log"
SCRIPT_PID=$$
USERNAME=$(whoami)

# === 日志函数 ===
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true; }

# === 检查必要命令 ===
check_env() {
    for cmd in whoami crontab pkill ps rm mkdir chmod uname uptime; do
        command -v "$cmd" >/dev/null 2>&1 || { red "缺少命令 $cmd"; exit 1; }
    done
}

# === 系统信息 ===
print_system_info() {
    cyan "┌───────────────────────────┐"
    cyan "│       系统信息概览        │"
    cyan "└───────────────────────────┘"
    echo ""
    echo "操作系统 / 内核: $(uname -srm)"
    echo "运行时间: $(uptime -p 2>/dev/null || uptime)"
    echo "负载平均: $(uptime 2>/dev/null | awk -F'load averages?: ' '{print $2}' | awk '{print $1,$2,$3}')"
    if command -v free >/dev/null 2>&1; then
        echo "内存使用: $(free -h | awk 'NR==2{print $3 " / " $2}')"
    elif command -v sysctl >/dev/null 2>&1; then
        physmem_bytes=$(sysctl -n hw.physmem 2>/dev/null || true)
        human_mem() { local b=$1; local u=(B K M G T); local i=0; while [ "$b" -ge 1024 ] && [ $i -lt 4 ]; do b=$((b/1024)); ((i++)); done; printf "%s%s\n" "$b" "${u[$i]}"; }
        echo "物理内存(总计, 近似): $(human_mem "$physmem_bytes")"
    fi
    if command -v lscpu >/dev/null 2>&1; then
        cpu_model=$(lscpu | awk -F: '/Model name/ {print $2; exit}' | sed 's/^[ \t]*//')
        cpu_cores=$(lscpu | awk -F: '/^CPU\(s\)/ {print $2; exit}' | sed 's/^[ \t]*//')
        echo "CPU: $cpu_model ($cpu_cores cores)"
    else
        echo "CPU: $(uname -p)"
    fi
    echo ""
}

# === 清理 cron ===
clean_cron() {
    log "清理 cron 任务"
    if crontab -l >/dev/null 2>&1; then
        crontab -r >/dev/null 2>&1 || true
        green "cron 任务已清空"
        log "Cron 清理完成"
    else
        green "无 cron 任务"
        log "未发现 cron 任务"
    fi
}

# === 终止用户进程 ===
kill_user_proc() {
    local count=0
    for pid in $(ps -U "$USERNAME" -o pid=); do
        pid=$(echo "$pid" | tr -d '[:space:]')
        [[ -z "$pid" || "$pid" == "$SCRIPT_PID" ]] && continue
        [[ "$pid" =~ ^[0-9]+$ ]] && kill -9 "$pid" >/dev/null 2>&1 && ((count++))
    done
    green "已终止 $count 个进程"
    log "终止 $count 个进程"
}

# === 删除目录 ===
clean_directory() {
    [ -d "$1" ] && rm -rf "$1" >/dev/null 2>&1 && green "已删除: $1" && log "删除 $1"
}

# === 恢复默认结构 ===
restore_defaults() {
    mkdir -p "$HOME/mail" "$HOME/repo"
    chmod 755 "$HOME/mail" "$HOME/repo"
    green "已创建 ~/mail 与 ~/repo"
    local domain_base="$HOME/domains/$USERNAME.serv00.net"
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access"
    chmod -R 755 "$domain_base"
    cat > "$domain_base/public_html/index.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
<title>default.site</title>
<meta charset="utf-8">
<style>
body { background: #1e1e1e; color: #00c8ff; font-family: monospace; text-align:center; padding:50px;}
.container { border:1px solid #00c8ff; padding:30px; border-radius:8px; max-width:600px; margin:0 auto;}
h1 { font-size:2em; margin-bottom:15px;}
p { font-size:1em; opacity:0.9;}
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
    chmod 644 "$domain_base/public_html/index.html"
    green "默认网站页面已生成"
}

# === 执行全自动系统重置 ===
init_server() {
    red "============================================================"
    red "警告：此操作将清空用户目录和进程，且不可撤销。"
    red "============================================================"
    echo ""
    yellow "执行全自动系统重置..."
    log "=== 开始系统重置 ==="

    # 1. 清理 cron
    cyan "[1/5] 清理 cron 任务..."
    clean_cron

    # 2. 清理缓存
    cyan "[2/5] 清理缓存目录..."
    for d in go .cache .npm .yarn .cargo/registry .local/share/Trash; do
        clean_directory "$HOME/$d"
    done

    # 3. 清理主目录（保留日志文件）
    cyan "[3/5] 清理主目录..."
    shopt -s dotglob nullglob 2>/dev/null || true
    for item in "$HOME"/* "$HOME"/.[!.]* "$HOME"/..?*; do
        [[ "$item" == "$LOG_FILE" ]] && continue
        [ -e "$item" ] && rm -rf "$item" >/dev/null 2>&1
    done
    green "主目录已清空（保留日志文件）"
    log "主目录清理完成"

    # 4. 恢复默认目录
    cyan "[4/5] 恢复默认结构..."
    restore_defaults

    # 5. 终止用户进程（最后）
    cyan "[5/5] 终止用户进程..."
    yellow "SSH 连接可能在几秒内断开..."
    kill_user_proc

    cyan "系统重置完成。"
    log "=== 系统重置完成 ==="
    green "默认网站: https://$USERNAME.serv00.net"
    [ -f "$LOG_FILE" ] && echo "日志文件: $LOG_FILE"
    echo ""
}

# === 主程序入口 ===
main() {
    check_env
    log "=== 脚本启动，用户: $USERNAME ==="
    print_system_info
    init_server
}

# 启动
main
