#!/bin/bash

# serv00 系统重置脚本 - 赛博朋克增强版
# 版本: 3.0
# 适配: FreeBSD (serv00.com)
# 风格: Cyberpunk Terminal UI

set -o pipefail

# === 颜色定义（赛博朋克霓虹色系）===
NEON_PURPLE='\033[38;5;129m'   # 主色调：霓虹紫
NEON_CYAN='\033[38;5;51m'      # 霓虹青
NEON_PINK='\033[38;5;201m'     # 霓虹粉
NEON_GREEN='\033[38;5;46m'     # 霓虹绿
NEON_YELLOW='\033[38;5;226m'   # 警告黄
NEON_RED='\033[38;5;196m'      # 危险红
RESET='\033[0m'

# 检测终端是否支持颜色
if [ -t 1 ]; then
    USE_COLOR=1
else
    USE_COLOR=0
fi

# 彩色函数（自动降级）
color() {
    local code="$1"; shift
    if [ "$USE_COLOR" = 1 ]; then
        echo -e "${code}$*${RESET}"
    else
        echo "$*"
    fi
}
purple() { color "$NEON_PURPLE" "$1"; }
cyan()   { color "$NEON_CYAN" "$1"; }
pink()   { color "$NEON_PINK" "$1"; }
green()  { color "$NEON_GREEN" "$1"; }
yellow() { color "$NEON_YELLOW" "$1"; }
red()    { color "$NEON_RED" "$1"; }

# === 配置 ===
LOG_FILE="$HOME/system_cleanup_$(date +%Y%m%d_%H%M%S).log"
SCRIPT_PID=$$

# === 日志 ===
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

# === 环境检查 ===
check_env() {
    for cmd in whoami crontab pkill ps rm mkdir chmod; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            red "❌ 错误: 缺少必要命令 $cmd"
            exit 1
        fi
    done
}

# === 清理 cron ===
clean_cron() {
    log "清理 cron 任务"
    if crontab -r 2>/dev/null; then
        green "✅ cron 任务已清空"
        log "Cron tasks cleared"
    else
        if crontab -l >/dev/null 2>&1; then
            yellow "⚠️  清理失败（权限问题？）"
            log "Failed to clear cron"
        else
            green "✅ 无 cron 任务，跳过"
            log "No cron tasks found"
        fi
    fi
}

# === 终止用户进程（排除自身）===
kill_user_proc() {
    local user=$(whoami)
    log "清理用户进程 (排除 PID: $SCRIPT_PID)"
    
    local count=0
    # FreeBSD 兼容：ps -U user -o pid=
    for pid in $(ps -U "$user" -o pid= 2>/dev/null); do
        [[ -z "$pid" || "$pid" == "$SCRIPT_PID" ]] && continue
        if kill -9 "$pid" 2>/dev/null; then
            ((count++))
        fi
    done
    
    if [ "$count" -eq 0 ]; then
        yellow "⚠️  未发现可清理的进程"
    else
        green "✅ 已终止 $count 个进程"
    fi
    log "Terminated $count processes"
}

# === 安全删除目录 ===
clean_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        return 0
    fi
    if rm -rf "$dir" 2>/dev/null; then
        green "✅ 已删除: $dir"
        log "Deleted: $dir"
    else
        yellow "⚠️  无法删除: $dir"
        log "Failed to delete: $dir"
    fi
}

# === 恢复默认结构 ===
restore_defaults() {
    local username=$(whoami)
    log "恢复默认目录结构"

    cyan "→ 创建基础目录..."
    mkdir -p "$HOME/mail" "$HOME/repo" && chmod 755 "$HOME/mail" "$HOME/repo"
    green "✅ ~/mail  ~/repo"

    local domain_base="$HOME/domains/$username.serv00.net"
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access"
    chmod -R 755 "$domain_base"

    # 默认 index.html
    cat > "$domain_base/public_html/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$username.serv00.net</title>
    <meta charset="utf-8">
    <style>
        body {
            background: #0f0c29;
            background: linear-gradient(to right, #24243e, #302b63, #0f0c29);
            color: #00ffea;
            font-family: 'Courier New', monospace;
            text-align: center;
            padding: 50px;
            margin: 0;
        }
        .cyber-box {
            border: 2px solid #ff00ff;
            box-shadow: 0 0 15px #00ffff, inset 0 0 10px rgba(0,255,255,0.3);
            padding: 30px;
            border-radius: 8px;
            max-width: 600px;
            margin: 0 auto;
            backdrop-filter: blur(5px);
        }
        h1 {
            font-size: 2.2em;
            text-shadow: 0 0 10px #ff00ff, 0 0 20px #ff00ff;
            margin: 0 0 20px;
        }
        p { font-size: 1.1em; opacity: 0.9; }
        .glitch {
            animation: glitch 3s infinite;
        }
        @keyframes glitch {
            0% { text-shadow: 0 0 10px #00ffff; }
            25% { text-shadow: -5px 0 #ff00ff, 5px 0 #00ffff; }
            50% { text-shadow: 0 0 10px #00ffff; }
            75% { text-shadow: 5px 0 #ff00ff, -5px 0 #00ffff; }
            100% { text-shadow: 0 0 10px #00ffff; }
        }
    </style>
</head>
<body>
    <div class="cyber-box">
        <h1 class="glitch">🌐 SYSTEM ONLINE</h1>
        <p>Welcome to <strong>$username.serv00.net</strong></p>
        <p>Server status: <span style="color:#00ff00">ACTIVE</span></p>
        <p style="font-size:0.9em; margin-top:25px;">// Powered by serv00.com //</p>
    </div>
</body>
</html>
EOF

    chmod 644 "$domain_base/public_html/index.html"
    green "✅ 默认网站已部署"
    log "Created default index.html"

    echo ""
    green "✅ 默认结构恢复完成"
}

# === 初始化系统 ===
init_server() {
    clear
    red "┌────────────────────────────────────────────────────────────┐"
    red "│                    ⚠️  DANGER ZONE ⚠️                       │"
    red "│           THIS ACTION CANNOT BE UNDONE!                    │"
    red "└────────────────────────────────────────────────────────────┘"
    echo ""
    yellow "THIS WILL:"
    echo "  • 🔥 Wipe all cron jobs"
    echo "  • 💀 Kill all your processes"
    echo "  • 🧹 Delete almost everything in your home directory"
    echo ""
    cyan "💡 serv00 自动保留最近 7 天备份（可通过面板恢复）"
    echo ""

    read -p "$(red 'Proceed with system reset? [y/N]: ')" input
    input=${input:-N}
    if [[ ! "$input" =~ ^[Yy]$ ]]; then
        yellow "🛑 Operation cancelled."
        log "Operation cancelled by user"
        return 0
    fi

    echo ""
    read -p "$(cyan 'Preserve config files (.bashrc, .ssh, etc)? [Y/n]: ')" saveProfile
    saveProfile=${saveProfile:-Y}

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    pink "🚀 INITIATING SYSTEM RESET PROTOCOL..."
    cyan "════════════════════════════════════════════════════════════"
    log "=== System reset started ==="

    # 1. Cron
    echo ""; cyan "[1/5] 🕒 Clearing cron jobs..."; clean_cron

    # 2. 特殊目录
    echo ""; cyan "[2/5] 🧹 Cleaning cache directories..."
    for d in go .cache .npm .yarn .cargo/registry .local/share/Trash; do
        [ -d "$HOME/$d" ] && clean_directory "$HOME/$d"
    done

    # 3. 主目录清理
    echo ""; cyan "[3/5] 🗑️  Purging home directory..."
    if [[ "$saveProfile" =~ ^[Yy]$ ]]; then
        green "→ Preserve mode: keeping dotfiles"
        # 删除非隐藏文件
        rm -rf "$HOME"/* 2>/dev/null
        green "✅ Non-hidden files purged"
        log "Purged non-hidden files"
    else
        yellow "→ Full purge mode: including dotfiles"
        # 启用安全 glob
        set +f  # 确保 glob 开启
        shopt -s nullglob dotglob 2>/dev/null || true
        for item in "$HOME"/* "$HOME"/.*; do
            case "$item" in
                "$HOME/."|"$HOME/.."|"$LOG_FILE") continue ;;
            esac
            rm -rf "$item" 2>/dev/null
        done
        shopt -u nullglob dotglob 2>/dev/null || true
        green "✅ Full home directory purged"
        log "Full home directory purged"
    fi

    # 4. 恢复默认
    echo ""; cyan "[4/5] 🏗️  Restoring default structure..."; restore_defaults

    # 5. 清理进程（最后）
    echo ""; cyan "[5/5] 💀 Terminating user processes..."
    yellow "⚠️  Connection may drop in 3 seconds..."
    sleep 1 && echo -n "3..." && sleep 1 && echo -n "2..." && sleep 1 && echo "1..."
    kill_user_proc

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    green "✅ SYSTEM RESET COMPLETE"
    cyan "════════════════════════════════════════════════════════════"
    log "=== System reset completed ==="

    echo ""
    pink "📌 POST-RESET INFO:"
    echo "  • Backup: serv00 keeps 7-day snapshots"
    echo "  • Default site: https://$username.serv00.net"
    echo "  • Directories created:"
    echo "      ~/mail, ~/repo, ~/domains/$username.serv00.net/{public_html,logs/access}"
    [ -f "$LOG_FILE" ] && echo "  • Log: $LOG_FILE"
    echo ""
}

# === 显示信息 ===
show_info() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                🖥️  SYSTEM STATUS REPORT                    │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "👤 User: $(whoami)"
    echo "🏠 Home: $HOME"
    echo "📍 PWD: $(pwd)"
    echo ""

    if command -v df >/dev/null; then
        disk=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
        echo "💾 Disk: $disk"
    fi

    cron_n=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
    proc_n=$(ps -U "$(whoami)" 2>/dev/null | wc -l)
    file_n=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    dir_n=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)

    echo ""
    echo "📊 Stats:"
    echo "  Cron Jobs: $cron_n"
    echo "  Processes: $proc_n"
    echo "  Home Files: $file_n"
    echo "  Home Dirs:  $dir_n"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
}

# === 主菜单 ===
show_menu() {
    clear
    echo ""
    purple "┌────────────────────────────────────────────────────────────┐"
    purple "│        🌐 serv00 CYBER RESET TERMINAL v3.0                 │"
    purple "│            「Neon Protocol Activated」                     │"
    purple "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  $(pink "1.") $(cyan "🗑️  FULL SYSTEM RESET")"
    echo "  $(pink "2.") $(cyan "🕒 CLEAR CRON JOBS")"
    echo "  $(pink "3.") $(cyan "💀 KILL USER PROCESSES")"
    echo "  $(pink "4.") $(cyan "📊 SYSTEM STATUS")"
    echo "  $(pink "5.") $(cyan "🚪 EXIT TERMINAL")"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
    read -p "$(pink ">> Select option [1-5]: ")" choice

    case $choice in
        1) init_server ;;
        2) echo ""; cyan "Executing: Clear cron"; clean_cron ;;
        3)
            echo ""; yellow "⚠️  This will kill all your processes (SSH may disconnect)"
            read -p "$(red "Confirm? [y/N]: ")" c; [[ "$c" =~ ^[Yy]$ ]] && { sleep 2; kill_user_proc; }
            ;;
        4) show_info ;;
        5)
            read -p "$(yellow "Exit terminal? [Y/n]: ")" e; [[ ! "$e" =~ ^[Nn]$ ]] && { green "🔌 Terminating session..."; exit 0; }
            ;;
        *) red "❌ Invalid option"; sleep 1 ;;
    esac
}

# === 信号处理 ===
trap 'log "Script interrupted by user"; exit 130' INT TERM

# === 主程序 ===
main() {
    check_env
    log "=== Script started by $(whoami) ==="
    while true; do
        show_menu
        echo ""; read -p "$(cyan "Press ENTER to return to menu...")" -r
    done
}

main
