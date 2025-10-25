#!/bin/bash

# serv00 系统重置脚本 - 赛博朋克增强版
# 版本: 3.0
# 适配: FreeBSD (serv00.com)
# 风格: 赛博终端 UI

set -o pipefail

# === 颜色定义（赛博朋克霓虹色系）===
NEON_PURPLE='\033[38;5;129m'   # 主色调：霓虹紫
NEON_CYAN='\033[38;5;51m'      # 辅助色：霓虹青
NEON_PINK='\033[38;5;201m'     # 点缀色：霓虹粉
NEON_GREEN='\033[38;5;46m'     # 状态色：霓虹绿
NEON_YELLOW='\033[38;5;226m'   # 警示色：明黄
NEON_RED='\033[38;5;196m'      # 危险色：警报红
RESET='\033[0m'

# 检测终端是否支持颜色输出
if [ -t 1 ]; then
    USE_COLOR=1
else
    USE_COLOR=0
fi

# 彩色输出函数（不支持颜色则自动降级为普通文本）
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

# === 配置区 ===
LOG_FILE="$HOME/system_cleanup_$(date +%Y%m%d_%H%M%S).log"
SCRIPT_PID=$$

# === 日志函数 ===
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

# === 清空定时任务（cron）===
clean_cron() {
    log "清理 cron 任务"
    if crontab -r 2>/dev/null; then
        green "✅ cron 任务已清空"
        log "Cron 任务已清理"
    else
        if crontab -l >/dev/null 2>&1; then
            yellow "⚠️  清理失败（可能是权限问题）"
            log "清理 cron 任务失败"
        else
            green "✅ 无 cron 任务，跳过"
            log "未发现 cron 任务"
        fi
    fi
}

# === 终止当前用户的所有进程（排除自身脚本）===
kill_user_proc() {
    local user=$(whoami)
    log "清理用户进程 (排除 PID: $SCRIPT_PID)"
    
    local count=0
    # FreeBSD 兼容模式：ps -U user -o pid=
    for pid in $(ps -U "$user" -o pid= 2>/dev/null); do
        [[ -z "$pid" || "$pid" == "$SCRIPT_PID" ]] && continue
        if kill -9 "$pid" 2>/dev/null; then
            ((count++))
        fi
    done
    
    if [ "$count" -eq 0 ]; then
        yellow "⚠️  未发现可终止的进程"
    else
        green "✅ 已终止 $count 个进程"
    fi
    log "已终止 $count 个进程"
}

# === 安全删除目录 ===
clean_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        return 0
    fi
    if rm -rf "$dir" 2>/dev/null; then
        green "✅ 已删除: $dir"
        log "已删除: $dir"
    else
        yellow "⚠️  无法删除: $dir"
        log "删除失败: $dir"
    fi
}

# === 恢复默认文件结构 ===
restore_defaults() {
    local username=$(whoami)
    log "恢复默认目录结构"

    cyan "→ 创建基础目录..."
    mkdir -p "$HOME/mail" "$HOME/repo" && chmod 755 "$HOME/mail" "$HOME/repo"
    green "✅ 已创建 ~/mail 与 ~/repo"

    local domain_base="$HOME/domains/$username.serv00.net"
    mkdir -p "$domain_base/public_html" "$domain_base/logs/access"
    chmod -R 755 "$domain_base"

    # 默认首页文件 index.html
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
        <p>欢迎访问 <strong>$username.serv00.net</strong></p>
        <p>服务器状态: <span style="color:#00ff00">正常运行</span></p>
        <p style="font-size:0.9em; margin-top:25px;">// Powered by serv00.com //</p>
    </div>
</body>
</html>
EOF

    chmod 644 "$domain_base/public_html/index.html"
    green "✅ 默认网站页面已生成"
    log "创建默认 index.html"

    echo ""
    green "✅ 默认结构恢复完成"
}

# === 初始化系统重置流程 ===
init_server() {
    clear
    red "┌────────────────────────────────────────────────────────────┐"
    red "│                    ⚠️  危险操作警告 ⚠️                     │"
    red "│           此操作将不可撤销！                               │"
    red "└────────────────────────────────────────────────────────────┘"
    echo ""
    yellow "执行后将进行以下操作："
    echo "  • 🔥 清空所有定时任务 (cron)"
    echo "  • 💀 终止当前用户的全部进程"
    echo "  • 🧹 删除用户目录下的大部分内容"
    echo ""
    cyan "💡 serv00 自动保留最近 7 天备份（可在面板中恢复）"
    echo ""

    read -p "$(red '是否继续执行系统重置？[y/N]: ')" input
    input=${input:-N}
    if [[ ! "$input" =~ ^[Yy]$ ]]; then
        yellow "🛑 操作已取消。"
        log "用户取消操作"
        return 0
    fi

    echo ""
    read -p "$(cyan '是否保留配置文件 (.bashrc, .ssh 等)? [Y/n]: ')" saveProfile
    saveProfile=${saveProfile:-Y}

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    pink "🚀 启动系统重置协议..."
    cyan "════════════════════════════════════════════════════════════"
    log "=== 开始系统重置 ==="

    # 1. 清理定时任务
    echo ""; cyan "[1/5] 🕒 正在清理 cron 任务..."; clean_cron

    # 2. 清理缓存目录
    echo ""; cyan "[2/5] 🧹 正在清理缓存目录..."
    for d in go .cache .npm .yarn .cargo/registry .local/share/Trash; do
        [ -d "$HOME/$d" ] && clean_directory "$HOME/$d"
    done

    # 3. 清理主目录
    echo ""; cyan "[3/5] 🗑️  正在清理主目录..."
    if [[ "$saveProfile" =~ ^[Yy]$ ]]; then
        green "→ 保留模式：保留隐藏文件"
        rm -rf "$HOME"/* 2>/dev/null
        green "✅ 已清理非隐藏文件"
        log "清理非隐藏文件"
    else
        yellow "→ 完全清理模式：包括隐藏文件"
        set +f
        shopt -s nullglob dotglob 2>/dev/null || true
        for item in "$HOME"/* "$HOME"/.*; do
            case "$item" in
                "$HOME/."|"$HOME/.."|"$LOG_FILE") continue ;;
            esac
            rm -rf "$item" 2>/dev/null
        done
        shopt -u nullglob dotglob 2>/dev/null || true
        green "✅ 已完全清空主目录"
        log "完全清空主目录"
    fi

    # 4. 恢复默认结构
    echo ""; cyan "[4/5] 🏗️  正在恢复默认结构..."; restore_defaults

    # 5. 清理用户进程
    echo ""; cyan "[5/5] 💀 正在终止用户进程..."
    yellow "⚠️  SSH 连接可能在 3 秒内断开..."
    sleep 1 && echo -n "3..." && sleep 1 && echo -n "2..." && sleep 1 && echo "1..."
    kill_user_proc

    echo ""
    cyan "════════════════════════════════════════════════════════════"
    green "✅ 系统重置完成"
    cyan "════════════════════════════════════════════════════════════"
    log "=== 系统重置完成 ==="

    echo ""
    pink "📌 重置后信息:"
    echo "  • 备份: serv00 保留最近 7 天快照"
    echo "  • 默认网站: https://$username.serv00.net"
    echo "  • 已创建目录:"
    echo "      ~/mail, ~/repo, ~/domains/$username.serv00.net/{public_html,logs/access}"
    [ -f "$LOG_FILE" ] && echo "  • 日志文件: $LOG_FILE"
    echo ""
}

# === 系统状态显示 ===
show_info() {
    clear
    cyan "┌────────────────────────────────────────────────────────────┐"
    cyan "│                🖥️  系统状态报告                            │"
    cyan "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "👤 用户: $(whoami)"
    echo "🏠 主目录: $HOME"
    echo "📍 当前路径: $(pwd)"
    echo ""

    if command -v df >/dev/null; then
        disk=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
        echo "💾 磁盘使用: $disk"
    fi

    cron_n=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
    proc_n=$(ps -U "$(whoami)" 2>/dev/null | wc -l)
    file_n=$(find "$HOME" -maxdepth 1 -type f 2>/dev/null | wc -l)
    dir_n=$(find "$HOME" -maxdepth 1 -type d 2>/dev/null | wc -l)

    echo ""
    echo "📊 统计信息:"
    echo "  Cron 任务数: $cron_n"
    echo "  进程数: $proc_n"
    echo "  文件数: $file_n"
    echo "  目录数: $dir_n"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
}

# === 主菜单界面 ===
show_menu() {
    clear
    echo ""
    purple "┌────────────────────────────────────────────────────────────┐"
    purple "│        🌐 serv00 赛博系统重置终端 v3.0                     │"
    purple "└────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  $(pink "1.") $(cyan "🗑️  执行完整系统重置")"
    echo "  $(pink "2.") $(cyan "🕒 清空 cron 定时任务")"
    echo "  $(pink "3.") $(cyan "💀 终止用户进程")"
    echo "  $(pink "4.") $(cyan "📊 查看系统状态")"
    echo "  $(pink "5.") $(cyan "🚪 退出终端")"
    echo ""
    cyan "────────────────────────────────────────────────────────────"
    read -p "$(pink ">> 请选择操作 [1-5]: ")" choice

    case $choice in
        1) init_server ;;
        2) echo ""; cyan "执行中: 清理 cron"; clean_cron ;;
        3)
            echo ""; yellow "⚠️  此操作将终止全部用户进程 (SSH 可能断开)"
            read -p "$(red "确认执行？[y/N]: ")" c; [[ "$c" =~ ^[Yy]$ ]] && { sleep 2; kill_user_proc; }
            ;;
        4) show_info ;;
        5)
            read -p "$(yellow "确定退出终端？[Y/n]: ")" e; [[ ! "$e" =~ ^[Nn]$ ]] && { green "🔌 结束会话..."; exit 0; }
            ;;
        *) red "❌ 无效选项"; sleep 1 ;;
    esac
}

# === 信号处理 ===
trap 'log "用户中断脚本执行"; exit 130' INT TERM

# === 主程序入口 ===
main() {
    check_env
    log "=== 脚本启动，执行用户: $(whoami) ==="
    while true; do
        show_menu
        echo ""; read -p "$(cyan "按 ENTER 返回主菜单...")" -r
    done
}

main
